# inference-study
Comparing the selling price  ($ per million tokens) vs e2e latency for various deployment configurations of a standard open source model



### setup
Begin by checking that docker is installed, nvidia-smi shows 8 working GPUs
```
docker ps
nvidia-smi
```

Pull latest docker image for vllm's openai compatible server
```
docker pull vllm/vllm-openai:latest
```

Check that model files are available. if no, download them from huggingface 
```
ls $HF_CACHE
```



