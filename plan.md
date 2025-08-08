```markdown
# UK FMCG Demand-Forecasting Mini-Project  
**Goal**: demonstrate **CatBoost vs TabPFN-TS vs SARIMAX** on 126-month UK food-store volume, driven by **consumer-confidence + CPI-food** shocks, wrapped in **90 % conformal prediction intervals**.

---

## 1. Data Sources (all open, ≤ 2 MB)

| Source | Granularity | Series | Link | Merge Key |
|---|---|---|---|---|
| ONS Retail Sales Index | Monthly | Food-store chained-volume sales | already downloaded | `date` |
| ONS Consumer-Confidence Index | Monthly | GfK consumer-confidence | [ONS CCLI](https://www.ons.gov.uk/economy/economicoutputandproductivity/timeseries/l2sc/mm23) | `date` |
| ONS CPI – Food & Non-Alcoholic Beverages | Monthly | CPI food | [ONS L55O](https://www.ons.gov.uk/economy/inflationandpriceindices/timeseries/l55o/mm23) | `date` |

---

## 2. Folder & Notebook Map

```
fmcg_forecast/
├── data/raw/              # original 3 CSVs
├── data/processed/        # cleaned & merged parquet
├── notebooks/
│   ├── 01_eda.ipynb       # line-plot + CPI/confidence overlay + regime spans
│   ├── 02_features.ipynb  # lag-1, lag-12, confidence, CPI → train/cal/test split
│   └── 03_modelling.ipynb # CatBoost, TabPFN-TS, SARIMAX → conformal PI
├── src/
│   ├── data_prep.py       # clean/merge
│   ├── models.py          # wrappers
│   └── conformal.py       # split-CP helpers
├── outputs/               # metrics.csv + forecast_plot.png
└── README.md              # 2-page summary
```

---

## 3. Feature Matrix (126 × 5)

| Column | Description |
|---|---|
| `sales_volume` | target |
| `confidence` | consumer-confidence index |
| `cpi_food` | CPI food |
| `lag_1` | sales[t-1] |
| `lag_12` | sales[t-12] |

Optional dummies: `lockdown_1`, `lockdown_2`, `cost_of_living`.

---

## 4. Train / Cal / Test Split
- **Train** 2015-01 → 2020-12 (72 rows)  
- **Calibration** 2021-01 → 2021-12 (12 rows)  
- **Test** 2022-01 → 2025-06 (42 rows)

---

## 5. Models & Conformal Setup

| Model | Library | Notes |
|---|---|---|
| **TabPFN-TS** | `tabpfn_ts` | zero-shot, CPU |
| **CatBoost** | `catboost` | all numeric |
| **SARIMAX** | `statsmodels` | exog = [confidence, CPI] |

Wrap best two ML models with **split-conformal** (α = 0.1) on the calibration set.

---

## 6. Evaluation Table & Plot

| Metric | TabPFN-TS | CatBoost | SARIMAX |
|---|---|---|---|
| MAE | … | … | … |
| 90 % Coverage | … | … | … |
| Avg PI Width | … | … | … |

---

## 7. Time Budget
- **Data cleaning & merge** 20 min  
- **EDA & regime spans** 30 min  
- **Feature & split** 15 min  
- **Modelling + CP** 45 min  
- **README + plots** 10 min  
**Total ≈ 2 h**

---

## 8. Deliverables
- GitHub repo with reproducible `run.py`  
- One concise README: data sources, metrics, plot of actual vs forecasts + 90 % bands.
```