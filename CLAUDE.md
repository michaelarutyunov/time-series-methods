# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This project investigates the dynamics of UK e-commerce growth, addressing the apparent stagnation in online retail share post-COVID despite frequent news reports of e-commerce growth. 

### Business Objective
Understand the true dynamics of e-commerce retail share by:
- Determining what the online retail share would be if pre-COVID trends had persisted
- Forecasting future evolution of e-commerce share (2026 projection)
- Testing the **reversion hypothesis**: Do post-COVID dynamics return to pre-COVID trends, or represent a new normal?
- Identifying which retail categories drive future growth vs. saturation

### Analytical Objectives
Analyze UK e-commerce trends using TabPFN (Transformer-based Prior-data Fitted Networks) for time-series forecasting:
- **Phase 1** (Notebooks 01-03): Aggregate analysis with exogenous economic variables to understand drivers and data leakage
- **Phase 2** (Notebooks 04-07): Category-level analysis using **regime dummies only** (no exogenous variables) to:
  - Compare three regimes: Pre-COVID, COVID, Post-COVID
  - Test reversion hypothesis per category
  - Generate bottom-up 2026 forecasts
  - Demonstrate TabPFN capabilities with proper leakage prevention

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

**Aggregate Analysis (Notebooks 01-03)**:
- **ONS Online Retail Sales Share**: Monthly percentage of online retail sales (2015-present)
- **ONS Consumer Price Index (CPI)**: Monthly inflation rate data
- **ONS Retail Price Index (RPI)**: Alternative inflation measure excluding CPI
- **ONS Effective Exchange Rate**: GBP effective exchange rate changes
- **GfK Consumer Confidence Index**: Monthly consumer sentiment data
- **Bank of England Rate**: Official bank rate changes

**Category-Level Analysis (Notebooks 04-07)** - NEW:
- **ONS Internet Reference Tables**: Category-level internet sales as proportion of retail (2009-present)
  - Source: `internetreferencetables.xlsx`, sheet `ISCPNSA3`
  - Categories: Food stores, Clothing & footwear, Household goods, Non-specialised, Other stores, Non-store retail

### Data Structure
```
data/
├── raw/                   # Original CSV files from various UK sources
│   ├── boe_rate_changes.csv                # Bank of England rate data
│   ├── gfk_consumer_confidence.csv         # GfK consumer confidence
│   ├── series-230925_GBPeffectivefx.csv    # GBP effective exchange rate
│   ├── series-230925_cpi.csv               # Consumer Price Index
│   ├── series-230925_onlineretailshare.csv # Online retail share
│   ├── series-230925_rpi.csv               # Retail Price Index
│   └── internetreferencetables.xlsx        # NEW: Category-level data
└── processed/            # Cleaned and integrated data
    ├── clean_data.csv        # Merged multi-variate time series (aggregate)
    ├── model_data.pkl        # Aggregate modeling data
    ├── meta_data.pkl         # Metadata for aggregate data
    ├── category_data.pkl     # NEW: Category-level time series (8 categories)
    ├── category_data.csv     # NEW: Human-readable category data
    └── category_metadata.pkl # NEW: Category descriptions and metadata
```

## Code Architecture

### Analysis Workflow (`notebooks/`)

**Phase 1: Aggregate Analysis (Notebooks 01-03)**
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

**Phase 2: Category-Level Analysis (Notebooks 04-07)** - NEW
5. **`04_category_data_prep.ipynb`**: Category-level data extraction and validation
   - Extracts 8 retail categories from ONS Internet Reference Tables
   - Data quality checks and validation
   - Initial visualization: small multiples showing category heterogeneity
   - Outputs: `category_data.pkl`, `category_data.csv`, `category_metadata.pkl`
6. **`05_category_regimes.ipynb`**: Regime-specific analysis per category (PLANNED)
   - Apply PELT changepoint detection to each category
   - Validate if universal breakpoints (Apr 2020, Feb 2022) hold per category
   - Profile each category by regime: pre-COVID, COVID, post-COVID dynamics
   - Statistical characterization: growth rates, volatility, regime differences
   - **Reversion metric**: `|growth_post - growth_pre| / |growth_covid - growth_pre|`
     - Close to 0 = full reversion to pre-COVID
     - Close to 1 = stuck in COVID dynamics
7. **`06_category_forecasts.ipynb`**: TabPFN forecasting per category (PLANNED)
   - **Features**: Regime dummies only (`d_cov`, `d_post`) - **NO exogenous variables**
   - **Rationale**: Economic variables (CPI, confidence) showed unstable relationships across regimes
   - For each category, generate 3 forecast scenarios to 2026:
     - **Scenario A (Reversion)**: Pre-COVID dynamics continue (`d_cov=0, d_post=0`)
     - **Scenario B (COVID Persistence)**: COVID dynamics persist (`d_cov=1, d_post=0`)
     - **Scenario C (Post-COVID Baseline)**: Post-COVID dynamics persist (`d_cov=1, d_post=1`)
   - **Data Leakage Prevention**: Progressive masking to ensure regime dummies don't leak future information
   - Evaluate forecast accuracy using holdout period
   - Compare which scenario best matches recent trends per category
8. **`07_aggregate_forecast.ipynb`**: Aggregation and 2026 forecast (PLANNED)
   - Weight category forecasts by retail sales volume
   - Generate bottom-up 2026 aggregate forecast (3 scenarios)
   - Compare to top-down approach on aggregate data
   - Sensitivity analysis: which categories drive uncertainty?
   - Final deliverable: 2026 forecast with confidence intervals per scenario

### Key Variables

**Aggregate Analysis Dataset (127 × 8)**:
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

**Category-Level Dataset (127 × 10)** - NEW:
- **Target Variables (8 categories)**:
  - `all_retail_ex_fuel`: All retailing excluding automotive fuel (aggregate reference)
  - `food_stores`: Predominantly food stores (supermarkets, grocers)
  - `non_food_total`: Total predominantly non-food stores (aggregate of subcategories)
  - `non_specialised`: Non-specialised stores (e.g., department stores)
  - `clothing_footwear`: Textile, clothing and footwear stores
  - `household_goods`: Household goods stores (furniture, electronics, DIY)
  - `other_stores`: Other stores (books, toys, sports equipment, etc.)
  - `non_store_retail`: Non-store retailing (mail order, markets, stalls - baseline ~75% online)
- **Features (regime dummies only)**:
  - `d_cov`: COVID regime dummy (April 2020 onwards) - marks structural break
  - `d_post`: Post-COVID regime dummy (February 2022 onwards) - marks normalization period
- **Exogenous Variables**: DROPPED for category-level analysis (unstable across regimes)

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

**Phase 1 (Aggregate) - Key findings from comparative analysis with exogenous variables:**
  - **Prediction 1** (data leakage): MAE: 0.372 - best performance but unrealistic (sees future exog)
  - **Prediction 2** (contemporaneous exog): MAE: 0.588 - realistic baseline with progressive masking
  - **Prediction 3** (lag-1 exog): MAE: 0.581 - similar to Prediction 2, strict no-leakage
  - **Prediction 4** (pre-COVID counterfactual): MAE: 1.128 - higher error vs actual post-COVID values (expected)
  - Progressive masking essential to prevent future information leakage
  - Data leakage improves MAE significantly but violates forecasting principles

**Phase 2 (Category-level) - Simplified approach with regime dummies only:**
  - **Decision**: Drop all exogenous variables (CPI, confidence, etc.)
  - **Rationale**: Economic variables showed unstable correlations across regimes (e.g., CPI +0.64 pre-COVID → -0.30 post-COVID)
  - **Features**: Only regime dummies (`d_cov`, `d_post`) to mark structural breaks
  - **Leakage Prevention**: Progressive masking ensures regime dummies don't leak future information
  - **Three-regime framework**: Pre-COVID (baseline), COVID (disruption), Post-COVID (new normal?)
  - **Forecast approach**: Generate scenarios by varying regime dummy values in 2026 predictions

### Model Evaluation Framework

**Phase 1 (Aggregate Analysis) - With Exogenous Variables:**
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

**Phase 2 (Category-Level Analysis) - With Regime Dummies Only:**
- **Data Leakage Prevention**: Progressive masking applied to regime dummies
  - For each forecast step at time t+h, regime dummies reflect **known** structural state at that time
  - Example: When forecasting 2026, model knows we're in post-COVID regime (`d_cov=1, d_post=1`)
  - Challenge: How to forecast under counterfactual regime states?
- **Three-Regime Framework**:
  - **Regime 1**: Pre-COVID (2015-01 to 2020-03) → `d_cov=0, d_post=0` (63 months)
  - **Regime 2**: COVID (2020-04 to 2022-01) → `d_cov=1, d_post=0` (22 months)
  - **Regime 3**: Post-COVID (2022-02 to 2025-07) → `d_cov=1, d_post=1` (42 months)
- **Scenario-Based Forecasting**: Generate 2026 forecasts under 3 regime assumptions:
  - **Scenario A**: Reversion to pre-COVID (`d_cov=0, d_post=0`)
  - **Scenario B**: COVID dynamics persist (`d_cov=1, d_post=0`)
  - **Scenario C**: Post-COVID baseline (`d_cov=1, d_post=1`)
- **Reversion Hypothesis Testing**: Compare post-COVID growth rates to pre-COVID baseline per category
- **Performance Metrics**: MAE, MASE on holdout period (2024-2025), scenario plausibility assessment

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

### Phase 1: Aggregate Analysis Findings

#### Business Question: **Is UK e-commerce growth truly stagnant?**

**Answer from Counterfactual Analysis:**
- Without COVID, online retail share would have grown steadily from ~22% (2020) to ~29% (2025)
- COVID caused an initial spike (~38% during lockdowns) followed by reversion
- By 2024-2025, actual values (~26-27%) are **below** the counterfactual (~29%)
- This suggests **COVID accelerated short-term adoption but disrupted long-term growth trajectory**
- The apparent "stagnation" in news reports reflects normalization from unsustainable pandemic highs, not true stagnation relative to pre-COVID trends

**However**: Aggregate analysis masks heterogeneous category dynamics. Phase 2 (category-level) investigates which sectors permanently shifted online vs. which reverted to physical retail.

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

### Phase 2: Category-Level Analysis (In Progress)

#### Motivation for Category-Level Approach

**Problem with Aggregate Analysis:**
- Post-COVID aggregate stagnation (-0.23 pp/year) masks heterogeneous dynamics
- Economic variables (CPI, confidence) lost explanatory power post-COVID
- Regime-specific correlations show complete reversal:
  - Pre-COVID: CPI +0.64, Consumer Confidence -0.82
  - Post-COVID: CPI -0.30, Consumer Confidence +0.23
- Aggregate relationships are **not stable across regimes**

**Category-Level Hypothesis:**
- Different retail categories experienced different COVID impacts:
  - Food stores: Likely permanent shift (convenience, habit formation)
  - Clothing: Temporary spike (work-from-home reduced demand)
  - Household goods: Potential saturation (nesting during lockdowns)
- Bottom-up category forecasts → more robust aggregate predictions
- Identifies which sectors drive future growth vs. which are saturating

**Key Decision: Drop Exogenous Variables for Phase 2**
- **Rationale**: Economic variables (CPI, consumer confidence) showed unstable relationships across regimes
- **Evidence**: Pre-COVID CPI correlation +0.64 → Post-COVID -0.30 (complete reversal)
- **Simplification**: Use only regime dummies (`d_cov`, `d_post`) as features
- **Benefits**:
  - Simpler TabPFN setup (2 features vs 7)
  - No need to forecast future exogenous values
  - Focus on structural breaks rather than economic drivers
  - Easier interpretation of regime-specific dynamics

#### Initial Findings from Notebook 04

**Data Availability**: Category breakdowns available 2009-present (127 months for 2015-2025 analysis)

**Category Online Penetration Ranges (2015-2025)**:
- **Non-store retail**: 69.7% → 88.7% (already predominantly online)
- **Clothing & footwear**: 11.2% → 26.0% (high COVID spike, partial reversion)
- **Household goods**: 6.2% → 22.6% (sustained growth post-COVID)
- **Food stores**: 4.1% → 9.5% (steady, linear growth - no COVID spike)
- **All retail aggregate**: 11.7% → 27.1% (reference)

**Next Steps** (Notebooks 05-07):
1. Regime-specific changepoint analysis per category
2. Category-level TabPFN forecasts (3 scenarios each)
3. Bottom-up aggregation → 2026 forecast with confidence intervals
4. Identify which categories drive future growth vs. saturation