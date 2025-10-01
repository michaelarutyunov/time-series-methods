# UK E-Commerce Growth Dynamics Analysis
**Goal**: Investigate UK e-commerce retail share dynamics post-COVID using **TabPFN time-series forecasting** to understand data leakage impact, exogenous variable importance, and counterfactual pre-COVID trends.

---

## 1. Data Sources (all open, monthly data 2015-2025)

| Source | Series | Link | Merge Key |
|---|---|---|---|
| ONS | Online retail sales share (%) | [J4MC/DRSI](https://www.ons.gov.uk/businessindustryandtrade/retailindustry/timeseries/j4mc/drsi) | `date` |
| ONS | Consumer Price Index (CPI) | [D7BT/MM23](https://www.ons.gov.uk/economy/inflationandpriceindices/timeseries/d7bt/mm23) | `date` |
| ONS | Retail Price Index (RPI) | [CHAW/MM23](https://www.ons.gov.uk/economy/inflationandpriceindices/timeseries/chaw/mm23) | `date` |
| ONS | GBP Effective Exchange Rate | [BK67/MRET](https://www.ons.gov.uk/economy/nationalaccounts/balanceofpayments/timeseries/bk67/mret) | `date` |
| Bank of England | Official Bank Rate | [Bank Rate](https://www.bankofengland.co.uk/boeapps/database/Bank-Rate.asp) | `date` |
| GfK (via Statista) | Consumer Confidence Index | [Statista](https://www.statista.com/statistics/623579/consumer-confidence-in-the-uk/) | `date` |

---

## 2. Project Structure

```
time-series-methods/
├── data/
│   ├── raw/              # Original CSV files from ONS/BOE/GfK
│   └── processed/        # clean_data.csv, model_data.pkl, meta_data.pkl
├── notebooks/
│   ├── 01_import.ipynb       # Data import, cleaning, merging from multiple sources
│   ├── 02_features.ipynb     # Structural break detection (PELT, Chow test), feature engineering
│   └── 03_modelling.ipynb    # TabPFN modeling with 4 prediction scenarios
├── outputs/figures/          # Generated visualizations
├── requirements.txt          # pip dependencies
├── environment.yml           # conda environment
├── pyproject.toml           # project metadata
└── CLAUDE.md                # AI assistant context
```

---

## 3. Feature Matrix (127 × 8)

| Column | Type | Description |
|---|---|---|
| `online_retail_sales_share` | Target | % of retail sales conducted online |
| `cpi_inf` | Exog | YoY CPI inflation (%) |
| `rpi_ex_cpi` | Exog | RPI - CPI spread (cost-of-living pressure) |
| `eff_fx_inf` | Exog | YoY GBP effective exchange rate change (%) |
| `cci` | Exog | GfK Consumer Confidence Index |
| `boe_rate` | Exog | Bank of England official rate (%) |
| `d_cov` | Dummy | COVID regime (April 2020+) |
| `d_post` | Dummy | Post-COVID regime (Feb 2022+) |

**Temporal features** (added in modeling):
- Calendar: `month`, `day_of_year`, `week_of_year`, `quarter`
- Lags: `lag_1`, `lag_2`, `lag_6`, `lag_12`
- Rolling means: `roll_mean_7`, `roll_mean_14`, `roll_mean_30`

---

## 4. Modeling Approach (TabPFN Time-Series)

### Prediction Scenarios

| Scenario | Exog Variables | Data Leakage | Purpose | MAE |
|---|---|---|---|---|
| **Prediction 1** | Contemporaneous (visible future) | ✅ Yes | Baseline to quantify leakage | 0.372 |
| **Prediction 2** | Progressive masking (no future) | ❌ No | Realistic forecast baseline | 0.588 |
| **Prediction 3** | Lag-1 + masking | ❌ No | Strict no-leakage test | 0.581 |
| **Prediction 4** | Pre-COVID counterfactual (STL) | ❌ No | What if COVID never happened? | 1.127* |

*Higher MAE expected - comparing counterfactual vs actual post-COVID values

### Key Findings

**Data Leakage Impact:**
- Future exog visibility improves MAE by 37% (0.588 → 0.372)
- Progressive masking essential to prevent leakage

**Exogenous Variable Importance** (from ablation study):
1. **CPI** (+106% MAE when removed) - Dominant predictor
2. **Consumer Confidence** (+23% MAE) - Important
3. **RPI ex CPI** (+11% MAE) - Redundant with CPI
4. **BOE Rate** (+3% MAE) - Minor
5. **FX Rate** (-20% MAE when removed) - Harmful, should remove

**Pre-COVID Counterfactual** (Prediction 4):
- Method: STL decomposition + linear trend projection + TabPFN residuals
- Trains on 2015-2020 Q1 (63 months, pre-COVID only)
- Counterfactual: 20% → 29% growth (2020-2025)
- Actual: Peaked at 38% (lockdowns), now ~26-27%
- Conclusion: COVID disrupted long-term growth trajectory

---

## 5. Structural Break Detection

**Method**: PELT (Pruned Exact Linear Time) + Chow Test validation

**Identified Breakpoints** (Bonferroni-corrected α=0.05):
- **April 2020**: First COVID lockdown (F=166.5, p<0.0001)
- **February 2022**: Post-COVID normalization (F=55.8, p<0.0001)

**Markov Regime-Switching**: Confirms 2 regimes (pre/post COVID)

---

## 6. Evaluation Metrics

| Metric | Pred 1 | Pred 2 | Pred 3 | Pred 4 |
|---|---|---|---|---|
| MAE | 0.372 | 0.588 | 0.581 | 1.127 |
| MASE | 0.121 | 0.192 | 0.189 | 3.164 |
| Pinball 0.1 | 0.109 | 0.195 | 1.099 | 0.751 |
| Pinball 0.9 | 0.138 | 0.580 | 0.446 | 0.219 |
| 80% Coverage | 83.3% | 91.7% | 91.7% | 8.3% |
| Mean PI Width | 2.17 | 7.57 | 15.43 | 0.38 |

---

## 7. Business Insights

### Is UK e-commerce truly stagnant?

**No.** The apparent "stagnation" reflects normalization from unsustainable pandemic highs:
- Pre-COVID trend: Steady 20% → 29% growth
- COVID spike: 38% peak (lockdown-driven)
- Current: ~26-27% (below counterfactual ~29%)
- **Conclusion**: COVID accelerated short-term adoption but disrupted long-term trajectory

### What drives e-commerce growth?

**Primary Driver**: Inflation (CPI)
- 106% error increase when removed
- High inflation → price comparison → online shopping

**Secondary Driver**: Consumer Confidence
- 23% error increase when removed
- Confident consumers experiment with new channels

**Non-drivers**: BOE rate (3%), FX rate (harmful)

---

## 8. Key Takeaways

1. **Data leakage prevention critical**: Progressive masking prevents 37% overoptimistic forecasts
2. **CPI dominates**: Inflation is the primary e-commerce driver, not secular trends
3. **COVID disrupted trends**: Actual 2025 values below pre-COVID counterfactual
4. **FX irrelevant**: UK e-commerce is domestic-focused; exchange rates add noise
5. **Optimal predictors**: CPI + Consumer Confidence (94% of exogenous value)

---

## 9. Technical Stack

**Core Libraries**:
- Data: pandas, numpy
- Visualization: matplotlib, seaborn
- ML: scikit-learn, tabpfn-client, tabpfn-time-series, autogluon.timeseries
- Time Series: statsmodels, sktime, ruptures
- Utils: scipy, python-dotenv

**Environment**: Python 3.12, Jupyter notebooks
