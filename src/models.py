from tabpfn import TabPFNRegressor
from catboost import CatBoostRegressor
from statsmodels.tsa.statespace.sarimax import SARIMAX


def fit_tabpfn_ts(X, y):
    model = TabPFNRegressor(device='cpu', random_state=42)
    model.fit(X, y)
    return model


def fit_catboost(X, y, cat_features=[]):
    model = CatBoostRegressor(iterations=1000, learning_rate=0.1, silent=True)
    model.fit(X, y, cat_features=cat_features)
    return model


def fit_sarima(y_train, order=(1, 1, 1), seasonal=(1, 1, 1, 52)):
    model = SARIMAX(y_train, order=order, seasonal_order=seasonal)
    return model.fit()
