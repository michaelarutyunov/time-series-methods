from sklearn.metrics import mean_absolute_error


def split_cp(model, X_cal, y_cal, X_test, alpha=0.1):
    preds_cal = model.predict(X_cal)
    residuals = np.abs(y_cal - preds_cal)
    q = np.quantile(residuals, 1 - alpha)
    preds_test = model.predict(X_test)
    lower = preds_test - q
    upper = preds_test + q
    return preds_test, lower, upper
