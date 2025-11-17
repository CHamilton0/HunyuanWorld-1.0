import io
import torch
import uvicorn
from fastapi import FastAPI
from fastapi.responses import StreamingResponse

# huanyuan3d image to panorama
# huanyuan3d text to panorama
from hy3dworld import Text2PanoramaPipelines
from hy3dworld.AngelSlim.attention_quantization_processor import FluxFp8AttnProcessor2_0
from hy3dworld.AngelSlim.cache_helper import DeepCacheHelper
from hy3dworld.AngelSlim.gemm_quantization_processor import FluxFp8GeMMProcessor
from PIL import Image


class Text2Panorama:
    def __init__(self, fp8_attention=False, fp8_gemm=False, cache=False):
        # set default parameters
        self.height = 960
        self.width = 1920

        self.fp8_attention = fp8_attention
        self.fp8_gemm = fp8_gemm
        self.cache = cache

        # panorama parameters
        # these parameters are used to control the panorama generation
        # you can adjust them according to your needs
        self.guidance_scale = 30
        self.shifting_extend = 0
        self.num_inference_steps = 50
        self.true_cfg_scale = 0.0
        self.blend_extend = 6

        # model paths
        self.lora_path = "tencent/HunyuanWorld-1"
        self.model_path = "black-forest-labs/FLUX.1-dev"
        # load the pipeline
        # use bfloat16 to save some VRAM
        self.pipe = Text2PanoramaPipelines.from_pretrained(self.model_path, torch_dtype=torch.bfloat16)
        # and enable lora weights
        self.pipe.load_lora_weights(
            self.lora_path,
            subfolder="HunyuanWorld-PanoDiT-Text",
            weight_name="lora.safetensors",
            torch_dtype=torch.bfloat16,
        )
        self.pipe.fuse_lora()
        self.pipe.unload_lora_weights()
        # save some VRAM by offloading the model to CPU
        self.pipe.enable_model_cpu_offload()
        self.pipe.enable_vae_tiling()  # and enable vae tiling to save some VRAM
        if self.fp8_attention:
            print("Set Fp8 Attention Processor!")
            self.pipe.transformer.set_attn_processor(FluxFp8AttnProcessor2_0())
        if self.fp8_gemm:
            print("Set Fp8 GeMM Processor!")
            FluxFp8GeMMProcessor(self.pipe.transformer)

    def run(self, prompt, negative_prompt=None, seed=42):
        # get panorama
        helper = None
        if self.cache:
            # Init deepcache helper
            helper = DeepCacheHelper(
                pipe_model=self.pipe.transformer,
                no_cache_steps=list(range(0, 10)) + list(range(10, 40, 3)) + list(range(40, 50)),
                no_cache_block_id={"single": [38]},
            )
            helper.start_timestep = 0
            # 打开 CacheHelper
            helper.enable()
        image = self.pipe(
            prompt,
            height=self.height,
            width=self.width,
            negative_prompt=negative_prompt,
            generator=torch.Generator("cpu").manual_seed(seed),
            num_inference_steps=self.num_inference_steps,
            guidance_scale=self.guidance_scale,
            blend_extend=self.blend_extend,
            true_cfg_scale=self.true_cfg_scale,
            helper=helper,
        ).images[0]

        # save the panorama image
        if not isinstance(image, Image.Image):
            image = Image.fromarray(image)

        return image


app = FastAPI()


@app.get("/")
def test():
    return {"status": "API is running"}


@app.get("/generate-panorama")
def generate_panorama(prompt: str, negative_prompt: str = ""):
    text_to_panorama_generator = Text2Panorama(fp8_attention=True, fp8_gemm=True, cache=True)
    panorama_image = text_to_panorama_generator.run(prompt, negative_prompt, seed=42)

    # Convert PIL Image to bytes
    img_byte_arr = io.BytesIO()
    panorama_image.save(img_byte_arr, format="PNG")
    img_byte_arr.seek(0)

    return StreamingResponse(img_byte_arr, media_type="image/png")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
