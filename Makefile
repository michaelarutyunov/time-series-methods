.PHONY: install notebook clean test

# Install dependencies
install:
	uv pip install -r requirements.txt

# Run Jupyter notebook
notebook:
	jupyter notebook

# Clean up generated files
clean:
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name "*.ipynb_checkpoints" -exec rm -rf {} +

# Run notebooks in order
run-all:
	jupyter nbconvert --to notebook --execute notebooks/01_eda.ipynb
	jupyter nbconvert --to notebook --execute notebooks/02_features.ipynb
	jupyter nbconvert --to notebook --execute notebooks/03_modelling.ipynb

# Setup development environment
setup:
	uv venv --python 3.12
	source .venv/bin/activate && uv pip install -r requirements.txt