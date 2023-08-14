from diffusers import DiffusionPipeline, StableDiffusionXLImg2ImgPipeline
import torch
import sys

model = "models/stable-diffusion-xl-base-1.0"
base = DiffusionPipeline.from_pretrained(
    model,
    torch_dtype=torch.float16,
)

base.to("cuda")

refiner_model = "models/stable-diffusion-xl-refiner-1.0"
refiner = StableDiffusionXLImg2ImgPipeline.from_pretrained(
    refiner_model,
    torch_dtype=torch.float16,
)
refiner.to("cuda")

input = ' '.join(sys.argv).split("#")
prompt = input[0]
seeds = input[1].split(",")

negative_prompt="((((ugly)))), (((words))), (((duplicate))), ((morbid)), ((mutilated)), out of frame, extra fingers, mutated hands, ((poorly drawn hands)), ((poorly drawn face)), (((mutation))), (((deformed))), blurry, ((bad anatomy)), (((bad proportions))), ((extra limbs)), cloned face, (((disfigured))), out of frame, extra limbs, (bad anatomy), gross proportions, (malformed limbs), ((missing arms)), ((missing legs)), (((extra arms))), (((extra legs))), mutated hands, (fused fingers), (too many fingers), (((long neck))), lowres, bad anatomy, bad hands, (((text))), error, missing fingers, extra digit, fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, ((watermark)), username, blurry, (artist name)"
positive_prompt=" ((masterpiece)), (top quality), (best quality), (highly detailed), (official art), (beautiful), (highres), (ultra detailed), (dynamic)"

prompt= prompt + positive_prompt

print(f"Using prompt: {prompt}")

for seed in seeds:
    print(f"Create {seed}.png")
    generator = torch.Generator("cuda").manual_seed(int(seed))
    image = base(
        prompt=prompt,
        generator=generator,
        num_inference_steps=80,
        guidance_scale=12,
        negative_prompt=negative_prompt,
    )
    image = image.images[0]
    image = refiner(
        prompt=prompt,
        generator=generator,
        image=image,
        num_inference_steps=20,
        guidance_scale=12,
        negative_prompt=negative_prompt,
    )
    image = image.images[0]
    image.save(f"images/{seed}.png")