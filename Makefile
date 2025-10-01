.PHONY: install notebook clean run-all setup help

# Default target - show help
help:
	@echo "Available commands:"
	@echo "  make setup       - Create virtual environment and install dependencies"
	@echo "  make install     - Install dependencies only"
	@echo "  make notebook    - Launch Jupyter notebook server"
	@echo "  make run-all     - Execute all notebooks in order"
	@echo "  make clean       - Remove generated files and cache"
	@echo "  make clean-data  - Remove processed data files"

# Setup development environment
setup:
	uv venv --python 3.12
	@echo "Virtual environment created. Activate with: source .venv/bin/activate"
	uv pip install -r requirements.txt

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
	rm -f =*

# Clean processed data (regenerate from notebooks)
clean-data:
	rm -f data/processed/*.csv
	rm -f data/processed/*.pkl
	rm -f data/processed/*.parquet
	rm -f data/processed/*.pq

# Run notebooks in order
run-all:
	jupyter nbconvert --to notebook --execute notebooks/01_import.ipynb --output 01_import.ipynb
	jupyter nbconvert --to notebook --execute notebooks/02_features.ipynb --output 02_features.ipynb
	jupyter nbconvert --to notebook --execute notebooks/03_modelling.ipynb --output 03_modelling.ipynb
	@echo "All notebooks executed successfully!"