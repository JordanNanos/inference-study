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

Launch the benchmark to measure runs with both tp 4 and tp 8 with the following script:
```
sh scripts/run-bench.sh
```

Note: this script includes a number of assumptions
* runs without docker
* tests tp 4 and tp 8 only
* sweeps --num-scheduler-steps from 2 to 16 to test for best performance on vLLM
* sweeps concurrency from 4 to 512 reqs to capture changes in E2EL as concurrency increases
* fixes input at 256 tokens, output at 128 tokens 
* log file paths are hard coded

view results in the `results/` directory

