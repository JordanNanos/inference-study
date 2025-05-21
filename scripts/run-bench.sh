#!/bin/bash

#source python environment
activate () {
  . .vllm/bin/activate
}
activate

#high level config
HF_CACHE=/scratch/local/huggingface
MODEL=meta-llama/Llama-3.3-70B-Instruct
BENCH=8xH100SXM-16k
DIR=results/$MODEL/$BENCH
HF_CACHE=$HF_CACHE
HF_HOME=$HF_CACHE
HOST=http://localhost:8000

#initial setup
mkdir -p $DIR


#load the model into local drive from remote storage
#rclone sync "${HF_HOME}/hub/models--${MODEL//\//--}/" "/lvol/hub/models--${MODEL//\//--}/" --transfers 32 --links --checkers 32

#define function to check if the model endpoint is ready
check_endpoint() {
    local response
    response=$(curl --silent "$HOST/v1/models")
    if echo "$response" | grep -i $MODEL; then
        return 0 #endpoint is up
    else 
        return 1 #endpoint is not up
    fi
}

#setup the params to sweep for performance testing
for NUM_STEPS in 1; do
    for TP in 8 4 2; do
        #for NUM_SEQS in 512; do
            #for NUM_TOKS in 1024; do
                mkdir -p $DIR/tp$TP-${NUM_STEPS}steps
                
                #if using docker
                #docker run -d --rm --gpus=all --name=bench -e HF_CACHE=$HF_CACHE -e HF_HOME=$HF_HOME -e HF_TOKEN=$HF_TOKEN -v /home/ubuntu/inference-study/vllm=vllm -v $DIR=$DIR -v $HF_CACHE=$HF_CACHE vllm/vllm-openai:latest --model $MODEL -tp $TP --swap-space 32 --max-model-len 1024 --disable-log-requests --gpu-memory-utilization 0.99 --max-num-seqs $NUM_SEQS --max-num-batched-tokens $NUM_TOKS --num-scheduler-steps $NUM_STEPS
                
                #if serving directly
                #nohup vllm serve $MODEL -tp $TP --enforce-eager --swap-space 32 --max-model-len 1024 --disable-log-requests --gpu-memory-utilization 0.99 --max-num-seqs $NUM_SEQS --max-num-batched-tokens $NUM_TOKS --num-scheduler-steps $NUM_STEPS &
                nohup vllm serve $MODEL -tp $TP --enforce-eager --swap-space 32 --disable-log-requests --gpu-memory-utilization 0.99 --num-scheduler-steps $NUM_STEPS &
                echo $! > save_pid.txt

                echo "Checking if the model endpoint is ready..."
                while ! check_endpoint "$HOST"; do
                    echo "Model endpoint is not ready. Waiting for 10 seconds..."
                    sleep 10
                done

                echo "Model endpoint is ready. Running benchmark..."
                
                #capture changes to E2EL as concurrency increases
                for con in 1 2 4 8 16 32 64 128 ; do 
                    for input in 16000; do 
                        for output in 16000; do 
                            #for random dataset
                            python -u vllm/benchmarks/benchmark_serving.py --disable-tqdm --model $MODEL --base_url $HOST --ignore-eos --max-concurrency $con --percentile-metrics ttft,tpot,itl,e2el --metric-percentiles 25,50,75,99 --random-range-ratio 0.8 --dataset-name random --request-rate inf --random-input-len ${input} --random-output-len ${output} --num-prompts 256 > $DIR/tp$TP-${NUM_STEPS}steps/${con}conn.log;
                            #for sharegpt
                            #python -u vllm/benchmarks/benchmark_serving.py --disable-tqdm --model $MODEL --base_url $HOST --ignore-eos --max-concurrency $con --percentile-metrics ttft,tpot,itl,e2el --metric-percentiles 25,50,75,99 --dataset-name sharegpt --dataset-path ./ShareGPT_V3_unfiltered_cleaned_split.json --request-rate inf --num-prompts 256 > $DIR/tp$TP-${NUM_STEPS}steps/${con}conn.log; 
                        done
                    done
                done
                
                #if using docker
                #docker rm -f bench

            #done
        #done
    done
done

#start the 
#docker run -d --rm --gpus=all --name=tp8 -e HF_TOKEN=$HF_TOKEN -e HF_CACHE=$HF_CACHE -e HF_HOME=$HF_CACHE -v /root/.cache/huggingface=$HF_CACHE vllm/vllm-openai:latest --model meta-llama/Llama-3.3-70B-Instruct -tp 8 --max-model-len 1024; docker logs -f tp8
#-e HF_HUB_OFFLINE=1 -e TRANSFORMERS_OFFLINE=1  -e HF_HOME=$HF_CACHE -e HF_CACHE=$HF_CACHE -e HF_TOKEN=$HF_TOKEN