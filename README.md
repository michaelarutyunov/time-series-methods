# UK E-Commerce Growth Dynamics Analysis

## Executive Summary

This project investigates the apparent stagnation in UK online retail share post-COVID, despite frequent news reports of e-commerce growth. Using TabPFN (Transformer-based Prior-data Fitted Networks) and counterfactual analysis, we reveal that COVID disrupted rather than accelerated long-term e-commerce trends.

### Key Findings

**1. E-Commerce Growth Trajectory**
- **COVID caused short-term acceleration but long-term disruption**: Online retail share spiked to ~38% during lockdowns, then reverted
- **Counterfactual scenario**: Without COVID, e-commerce would have grown steadily from ~22% (2020) to ~29% (2025)
- **Current state (2024-2025)**: Actual values (~26-27%) are **below** pre-COVID trend projection
- **Business implication**: The "stagnation" reflects normalization from unsustainable pandemic highs, not true stagnation

**2. Economic Drivers of E-Commerce Adoption**

Feature ablation study reveals:

| Factor | MAE Impact | Business Insight |
|--------|-----------|------------------|
| **CPI Inflation** | +106% | **Dominant driver** - price-conscious behavior drives online shopping |
| **Consumer Confidence** | +23% | **Important** - sentiment shapes channel adoption |
| RPI (ex-CPI) | +11% | Redundant with CPI (multicollinearity) |
| BOE Interest Rate | +3% | Negligible - rates don't affect channel choice |
| **GBP Exchange Rate** | -20% | **Harmful** - UK e-commerce is domestic-focused, FX adds noise |

**Optimal predictor set**: CPI + Consumer Confidence (94% of exogenous value)

## Project Structure

```
time-series-methods/
├── data/
│   ├── raw/                                    # Original data sources
│   │   ├── series-230925_onlineretailshare.csv # ONS online retail share (2015-present)
│   │   ├── series-230925_cpi.csv               # Consumer Price Index
│   │   ├── series-230925_rpi.csv               # Retail Price Index
│   │   ├── series-230925_GBPeffectivefx.csv    # GBP effective exchange rate
│   │   ├── gfk_consumer_confidence.csv         # GfK consumer confidence
│   │   └── boe_rate_changes.csv                # Bank of England rate
│   └── processed/
│       ├── clean_data.csv                      # Merged multi-variate time series
│       └── model_data.pq                       # Parquet format for modeling
├── notebooks/
│   ├── 01_import.ipynb         # Data import, cleaning, integration
│   ├── 02_features.ipynb       # Feature engineering, structural break detection
│   └── 03_modelling.ipynb      # TabPFN forecasting experiments
└── outputs/
    └── figures/                # Visualizations
```

## Methodology

### Data Architecture
- **Time period**: 2015-01 to present (monthly observations)
- **Target variable**: `online_retail_sales_share` (% of retail sales online)
- **Exogenous variables**: CPI, RPI, GBP FX rate, consumer confidence, BOE rate
- **Structural breaks**: April 2020 (COVID), February 2022 (post-COVID) - detected via PELT algorithm

### Modeling Approach: TabPFN Experiments

**Prediction 1: Baseline with Data Leakage** (MAE: 0.372)
- Future exogenous variables visible to model
- Best performance but unrealistic (violates forecasting principles)

**Prediction 2: Leak-Free with Progressive Masking** (MAE: 0.588)
- Contemporaneous exogenous variables only
- Progressive masking: for each forecast step t+h, only features up to t+h visible
- **Realistic baseline performance**

**Prediction 3: Lag-1 Exogenous + Masking** (MAE: 0.581)
- Strict no-leakage: only past exogenous values used
- Similar performance to Prediction 2 → timing doesn't matter much

**Prediction 4: Pre-COVID Counterfactual** (MAE: 1.128 vs actual post-COVID)
- **Challenge**: TabPFN predicted flat ~17% (mean) instead of continuing trend
- **Solution**: STL decomposition approach
  1. Fit model on 2015-2020 Q1 data (63 months, pre-COVID only)
  2. Decompose into trend, seasonal, residual components
  3. Extrapolate linear trend + repeat seasonal pattern + forecast residuals with TabPFN
  4. Recompose to create realistic counterfactual
- **Result**: Shows what e-commerce growth would have been without COVID

### Performance Metrics
- MAE (Mean Absolute Error)
- MASE (Mean Absolute Scaled Error)
- Pinball loss (0.1, 0.9 quantiles)
- 80% prediction interval coverage and width

## Setup

```bash
# Install dependencies
pip install -r requirements.txt
# or using uv
uv sync
```

### Key Dependencies
- **Data**: pandas, numpy
- **Visualization**: matplotlib, seaborn
- **ML**: tabpfn-time-series, autogluon.timeseries, scikit-learn
- **Time Series**: statsmodels, sktime, ruptures
- **Other**: scipy, python-dotenv

### Running the Analysis

```bash
# Launch Jupyter
jupyter notebook

# Run notebooks sequentially:
# 1. notebooks/01_import.ipynb      - Data preparation
# 2. notebooks/02_features.ipynb    - Feature engineering
# 3. notebooks/03_modelling.ipynb   - TabPFN experiments
```

## Data Sources

- **ONS Online Retail Sales Share**: Monthly percentage of online retail sales (2015-present)
- **ONS Consumer Price Index (CPI)**: Monthly inflation rate data
- **ONS Retail Price Index (RPI)**: Alternative inflation measure
- **ONS Effective Exchange Rate**: GBP effective exchange rate changes
- **GfK Consumer Confidence Index**: Monthly consumer sentiment data
- **Bank of England Rate**: Official bank rate changes

## Business Implications

1. **E-commerce growth is inflation-driven, not secular**: High inflation drives price comparison behavior → online channel adoption
2. **COVID disrupted long-term trends**: Short-term spike masks underlying deceleration vs pre-COVID trajectory
3. **News reports of "stagnation" are misleading**: Comparing to pandemic peaks (38%) rather than counterfactual trend (29%)
4. **Optimal forecasting requires only CPI + consumer confidence**: Other economic indicators add noise or redundancy
5. **Exchange rates are irrelevant for UK e-commerce**: Domestic focus means FX fluctuations don't affect channel choice

## License

This project is for academic and analytical purposes.
