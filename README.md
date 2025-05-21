# Inference Study
Comparing the selling price  ($ per million tokens) vs e2e latency for various deployment configurations of a standard open source model



### Initial Setup
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

Clone the latest version of vllm from github, for the benchmark script
```
git clone https://github.com/vllm-project/vllm.git
```

Install vllm in a venv:
```
python -m venv .vllm
source .vllm/bin/activate
pip install uv
uv pip install vllm
uv pip install pandas datasets matplotlib #needed for the benchmark script and generating plots
```

Launch the -tp 8 benchmark with the following script:
```
sh scripts/run-tp8-bench.sh
``


