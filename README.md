# Naive LLM C-to-Rust Translation

This repository implements a baseline, naive LLM-based translation from C to Rust using calls to OpenAI's GPT5 model.

It executes the GPT5 conversion with the following call to `naive.py`: 

```
        s3_key = os.environ.get("S3_KEY")
        if s3_key.endswith(("lib.tar.gz", "lib.tgz")):
            demo_cmd = ["python3", "/app/naive.py", str(tmpdir), str(outdir), "--c-compatible-lib", "--openai", "gpt-5"]
        else:
            demo_cmd = ["python3", "/app/naive.py", str(tmpdir), str(outdir), "--openai", "gpt-5"]
```
