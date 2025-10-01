# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This project investigates the dynamics of UK e-commerce growth, addressing the apparent stagnation in online retail share post-COVID despite frequent news reports of e-commerce growth. 

### Business Objective
Understand the true dynamics of e-commerce retail share by:
- Determining what the online retail share would be if pre-COVID trends had persisted
- Forecasting future evolution of e-commerce share
- Assessing whether selected exogenous factors (CPI, RPI, exchange rates, consumer confidence, BOE rates) help explain e-commerce dynamics

### Analytical Objectives
Analyze UK e-commerce trends using TabPFN (Transformer-based Prior-data Fitted Networks) for time-series forecasting with multiple experimental scenarios to understand data leakage, exogenous variable impact, and counterfactual pre-COVID trends.

## Development Environment Setup

Install dependencies:
```bash
pip install -r requirements.txt
# or using uv (modern Python package manager)
uv sync
```

The project uses Python with these key libraries:
- Data manipulation: pandas, numpy
- Visualization: matplotlib, seaborn
- ML models: scikit-learn, tabpfn-time-series, autogluon.timeseries
- Time series analysis: statsmodels, sktime, ruptures
- Additional: scipy for statistical analysis, python-dotenv for API key management

## Data Architecture

### Data Sources
- **ONS Online Retail Sales Share**: Monthly percentage of online retail sales (2015-present)
- **ONS Consumer Price Index (CPI)**: Monthly inflation rate data
- **ONS Retail Price Index (RPI)**: Alternative inflation measure excluding CPI
- **ONS Effective Exchange Rate**: GBP effective exchange rate changes
- **GfK Consumer Confidence Index**: Monthly consumer sentiment data
- **Bank of England Rate**: Official bank rate changes

### Data Structure
```
data/
├── raw/                   # Original CSV files from various UK sources
│   ├── boe_rate_changes.csv               # Bank of England rate data
│   ├── gfk_consumer_confidence.csv        # GfK consumer confidence
│   ├── series-230925_GBPeffectivefx.csv   # GBP effective exchange rate
│   ├── series-230925_cpi.csv              # Consumer Price Index
│   ├── series-230925_onlineretailshare.csv # Online retail share
│   └── series-230925_rpi.csv              # Retail Price Index
└── processed/            # Cleaned and integrated data
    ├── clean_data.csv        # Merged multi-variate time series
    ├── model_data.pq         # Parquet format for modeling
    └── model_data.meta       # Metadata for processed data
```

## Code Architecture

### Analysis Workflow (`notebooks/`)
1. **`01_import.ipynb`**: Data import, cleaning, and integration from multiple ONS/BOE sources
2. **`02_features.ipynb`**: Feature engineering and structural break detection (PELT, Chow test)
3. **`03_modelling.ipynb`**: Multi-variate modeling with TabPFN including:
   - **Prediction 1**: Baseline with data leakage (future exogenous variables visible)
   - **Prediction 2**: Leak-free with progressive masking (contemporaneous exogenous variables)
   - **Prediction 3**: Lag-1 exogenous + masking (strict no-leakage, poor performance)
   - **Prediction 4**: Pre-COVID counterfactual using STL decomposition approach
     - Trains on 2015-2020 Q1 (63 months, pre-COVID only)
     - Uses STL decomposition: separates trend, seasonal, and residual components
     - Applies TabPFN to residuals, then recomposes with linear trend projection
     - Evaluates using `tsdf_train` (pre-COVID data) for MASE calculation consistency
4. **`03_modelling_old.ipynb`**: Previous modeling approach (archived)

### Key Variables
The integrated dataset includes:
- **Target Variable:**
  - `online_retail_sales_share`: Percentage of retail sales conducted online (dependent variable)
- **Exogenous Factors (ranked by predictive importance from ablation study):**
  1. `cpi_inf`: Consumer Price Index inflation rate (**Most Important** - 106% MAE increase when removed)
  2. `cci`: Consumer Confidence Index (**Important** - 23% MAE increase when removed)
  3. `rpi_ex_cpi`: Retail Price Index excluding CPI (**Moderate** - 11% MAE increase, redundant with CPI)
  4. `boe_rate`: Bank of England official rate (**Minor** - 3% MAE increase)
  5. `eff_fx_inf`: Effective exchange rate inflation (**Harmful** - 20% MAE *decrease* when removed)
- **Structural Break Indicators:**
  - `d_cov`: COVID-19 regime dummy (April 2020 onwards)
  - `d_post`: Post-COVID regime dummy (February 2022 onwards)

### Time Period Coverage
- **Data Range**: 2015-01 → Present
- **Frequency**: Monthly observations
- **Integration**: All series aligned to month-end dates for consistency

## Model Implementation Details

### SARIMAX
- Seasonal ARIMA with exogenous variables
- Incorporates trend, seasonality, and external economic factors
- Used to model online retail share with economic predictors

### XGBoost
- Gradient boosting for time-series regression
- Handles non-linear relationships between exogenous factors
- Feature engineering includes lags and rolling statistics

### TabPFN (Primary Focus)
- Transformer-based Prior-data Fitted Networks
- Zero-shot time series forecasting without traditional training
- Uses TabPFN Client API (`TabPFNMode.CLIENT`)
- Key findings from comparative analysis:
  - **Prediction 1** (data leakage): MAE: 0.372 - best performance but unrealistic (sees future exog)
  - **Prediction 2** (contemporaneous exog): MAE: 0.588 - realistic baseline with progressive masking
  - **Prediction 3** (lag-1 exog): MAE: 0.581 - similar to Prediction 2, strict no-leakage
  - **Prediction 4** (pre-COVID counterfactual): MAE: 1.128 - higher error vs actual post-COVID values (expected)
  - Progressive masking essential to prevent future information leakage
  - Data leakage improves MAE significantly but violates forecasting principles

### Model Evaluation Framework
- **Data Leakage Prevention**: Progressive masking ensures test set only sees exogenous features up to forecast horizon h
  - **Prediction 2 & 3**: Implement progressive masking where for each forecast step t+h, only exog variables up to t+h are visible
  - **Masking Logic**: Nested loop that sets future exog values to NaN for each prediction horizon
- **Pre-COVID Analysis**: Fit models on 2015-2020 Q1 data (63 months) to understand baseline trends
- **Counterfactual Analysis (Prediction 4)**:
  - **Method**: STL decomposition + linear trend projection
    1. Apply STL to pre-COVID data → extract trend, seasonal, residual components
    2. Fit linear trend model to extrapolate deterministic growth
    3. Apply TabPFN to residuals (stochastic component)
    4. Recompose: forecasted residuals + projected trend + repeated seasonal pattern
  - **Rationale**: TabPFN struggles with long-horizon trend extrapolation (predicts mean ~17% instead of trend)
  - **Results**: Counterfactual shows steady growth from 20% → 29% (2020-2025)
  - **COVID Impact**: Actual post-COVID values initially higher (~38% peak during lockdowns), then converge toward counterfactual by 2024-2025
  - **Important**: Uses `tsdf_train` (pre-COVID data) for MASE calculation, not `train_tsdf` (full-period data)
- **Full Period Analysis (Predictions 1-3)**: Model entire 2015-present period including COVID effects
- **Performance Metrics**: MAE, MASE, pinball loss (0.1, 0.9 quantiles), 80% coverage, interval width

## Development Commands

Run Jupyter notebooks:
```bash
jupyter notebook
# Navigate to notebooks/ directory
```

For Python scripts:
```bash
python src/data_prep.py
python src/models.py
```

## Output Structure

```
outputs/
└── figures/              # Generated visualizations
    ├── RSI_*.png        # Retail Sales Index analysis plots
    ├── features_correlations.png
    └── markov_regime_probs.png
```

## Project Workflow

1. **Data Integration**: Import and align UK economic time series (2015-present)
2. **Exploratory Analysis**: Identify COVID impact on e-commerce trends and structural breaks
   - Structural breaks detected: April 2020 (COVID), February 2022 (post-COVID)
   - Changepoint detection using PELT algorithm and Chow test validation
3. **Data Leakage Investigation**: Compare forecasts with/without future exogenous variables
   - Discovered 6.5% performance improvement from data leakage
   - Implemented progressive masking to prevent leakage
4. **Pre-COVID Modeling**: Fit TabPFN on 2015-2020 Q1 data (before first structural break)
5. **Counterfactual Analysis**: Generate what online retail share would be without COVID
   - **Key Challenge**: TabPFN predicted flat ~17% (mean) instead of continuing growth trend
   - **Solution**: STL decomposition approach
     - Separate deterministic trend, seasonal pattern, and stochastic residuals
     - Extrapolate linear trend, repeat seasonal pattern, forecast residuals with TabPFN
     - Recompose to create realistic counterfactual forecast
   - **Result**: Counterfactual shows 20% → 29% growth, revealing COVID's long-term impact
   - **Technical Note**: Critical to use pre-COVID training data (`tsdf_train`) for evaluation metrics, not full-period data
6. **Exogenous Factor Analysis**: Assess contribution of economic indicators using feature ablation
   - **Method**: Remove each exogenous variable individually and measure MAE increase
   - **CPI dominates**: 106% error increase when removed (0.588 → 1.211 MAE)
   - **Consumer Confidence matters**: 23% error increase when removed
   - **RPI redundancy**: Only 11% increase despite high correlation (0.66) - multicollinear with CPI
   - **FX is harmful**: Model performs 20% *better* without it - UK e-commerce is domestic, FX adds noise
   - **Timing doesn't matter**: Contemporaneous vs lag-1 exog show similar performance (0.588 vs 0.581 MAE)
7. **Model Comparison**: Evaluate performance across different configurations and time periods

## Key Findings

### Business Question: **Is UK e-commerce growth truly stagnant?**

**Answer from Counterfactual Analysis:**
- Without COVID, online retail share would have grown steadily from ~22% (2020) to ~29% (2025)
- COVID caused an initial spike (~38% during lockdowns) followed by reversion
- By 2024-2025, actual values (~26-27%) are **below** the counterfactual (~29%)
- This suggests **COVID accelerated short-term adoption but disrupted long-term growth trajectory**
- The apparent "stagnation" in news reports reflects normalization from unsustainable pandemic highs, not true stagnation relative to pre-COVID trends

### Economic Drivers: **What factors drive UK e-commerce growth?**

**Answer from Feature Ablation Study:**

**Primary Driver - Inflation (CPI):**
- **Dominant signal**: Removing CPI increases forecast error by 106% (0.588 → 1.211 MAE)
- **Mechanism**: High inflation drives price comparison behavior → online shopping increases
- **Business insight**: E-commerce growth is inflation-sensitive, not a secular trend

**Secondary Driver - Consumer Confidence:**
- **Important signal**: Removing confidence increases error by 23%
- **Mechanism**: Confident consumers experiment with new channels (online)
- **Business insight**: Economic sentiment shapes channel adoption rates

**Surprising Non-Drivers:**
- **RPI redundant**: Despite 0.66 correlation, only 11% impact (multicollinear with CPI)
- **BOE Rate negligible**: Only 3% impact - interest rates don't affect channel choice
- **FX Rate harmful**: Model improves 20% without it - UK e-commerce is domestic-focused

**Optimal Predictor Set**: CPI + Consumer Confidence (accounts for 94% of exogenous value)

**Model Recommendation**: Remove FX from future models for improved accuracy and interpretability