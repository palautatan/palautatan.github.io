# * LOAD DATA
engagement <- read_csv("../../data/engagement-ring.csv", col_names=TRUE)
names(engagement) <- c("date", "search")

engagement <- engagement %>% mutate(date=paste0(date, "-01"))
engagement <- engagement %>% mutate(date=as.Date(date, "%Y-%m-%d"))

# * DATA SUBSET
min <- as.Date("2011-12-31")
max <- max(engagement$date)
engagement_sub <- engagement %>% filter(date>min) %>% filter(date<max)


# * DATA EXPLORATION
# * SEARCH DATA IS SKEWED RIGHT
ggplot(engagement_sub, aes(x=search)) +
  geom_histogram(fill="skyblue", col="black", lwd=0.3) +
  theme_minimal()

ggplot(engagement_sub, aes(sample=search)) +
  stat_qq(alpha=0.5) +
  stat_qq_line() +
  theme_minimal()


# * CREATE LINEAR MODEL
ab_trend     <- lm(search~as.numeric(date), data=engagement_sub)

poly_trend_2 <- lm(search~as.numeric(date) + I(as.numeric(date)^2), data=engagement_sub)

poly_trend_3 <- lm(search~as.numeric(date) + I(as.numeric(date)^2) + I(as.numeric(date)^3), data=engagement_sub)



# * BOX-COX
# * BEST: https://www.youtube.com/watch?v=vGOpEpjz2Ks
# * https://www.statisticshowto.datasciencecentral.com/box-cox-transformation/
# * https://stackoverflow.com/questions/33999512/how-to-use-the-box-cox-power-transformation-in-r
library(MASS)
bc_ab       <- boxcox(ab_trend, lambda=seq(-5,3))
lambda_1    <- bc_ab$x[which.max(bc_ab$y)]

bc_poly_2   <- boxcox(poly_trend_2, lambda=seq(-5,3)) # * BOX-COX INVARIANT(?) FOR MODELS
lambda_2    <- bc_ab$x[which.max(bc_ab$y)]

new_poly    <- lm(search^lambda_1 ~ as.numeric(date) + I(as.numeric(date)^2), data=engagement_sub)



# * CREATE PLOTTABLE STAT FUNCTIONS
ab_trend_p     <- function(x) 50.3715576 - -0.0002097*as.numeric(x)

poly_trend_2_p <- function(x) 5.211e+02 -5.677e-02*as.numeric(x) + 1.696e-06*as.numeric(x)^2

poly_trend_3_p <- function(x) 2.967e+03 -4.978e-01*as.numeric(x) + 2.817e-05*as.numeric(x)^2 + -5.291e-10*as.numeric(x)^3

new_poly_p     <- function(x) -1.257e-03 + 1.560e-07*as.numeric(x) -4.639e-12*as.numeric(x)^2


# * PLOT FOR 2012 ON
ggplot(engagement_sub, aes(x=date, y=search)) + 
  geom_point(size=0.8, col="lightblue") + 
  geom_line(alpha=0.5) +
  scale_x_date(date_breaks="1 year", labels=date_format("%Y-%m")) +
  ylab("google interest") +
  xlab("") +
  ggtitle("Engagement Ring Interest Starting 2012") +
  theme_minimal() + 
  theme(axis.text.x = element_text(angle = 90)) +
  geom_abline(slope=-0.0002097, intercept=50.3715576, lwd=1, alpha=0.7, colour="cornflowerblue") +
  stat_function(fun=poly_trend_2_p, colour="navy", lwd=1, alpha=0.7)


# * BOX COX PLOTS
engagement_sub <- engagement_sub %>% mutate(tf_search=search^lambda_1)

ggplot(engagement_sub, aes(sample=tf_search)) + # * SUBTLE IMPROVEMENT
  stat_qq(alpha=0.5) +
  stat_qq_line() +
  theme_minimal()

ggplot(engagement_sub, aes(x=date, y=tf_search)) +
  geom_point(size=0.8, col="lightblue") + 
  geom_line(alpha=0.5) +
  scale_x_date(date_breaks="1 year", labels=date_format("%Y-%m")) +
  ylab("google interest") +
  xlab("") +
  ggtitle("Engagement Ring Interest Starting 2012") +
  theme_minimal() + 
  theme(axis.text.x = element_text(angle = 90)) +
  stat_function(fun=new_poly_p, colour="lightblue", lwd=1, alpha=0.7)


# * REMOVE TREND
engagement_sub$fitted_trend <- new_poly$fitted.values
engagement_sub <- engagement_sub %>% mutate(detrended=tf_search-fitted_trend)

ggplot(engagement_sub, aes(x=date, y=detrended)) + 
  geom_point(size=0.8, col="lightblue") + 
  geom_line(alpha=0.5) +
  scale_x_date(date_breaks="1 year", labels=date_format("%Y-%m")) +
  ylab("google interest") +
  xlab("") +
  ggtitle("Engagement Ring Interest Starting 2012") +
  theme_minimal() + 
  theme(axis.text.x = element_text(angle = 90))



# * REMOVE SEASONALITY
# * https://anomaly.io/seasonal-trend-decomposition-in-r/
# library(forecast)
# 
# engagement_sub <- engagement_sub %>% mutate(ma=ma(detrended, order=12, centre=T))
# ggplot(engagement_sub, aes(x=date, y=detrended)) + 
#   geom_point(size=0.8, col="lightblue") + 
#   geom_line(alpha=0.3) +
#   scale_x_date(date_breaks="1 year", labels=date_format("%Y-%m")) +
#   ylab("google interest") +
#   xlab("") +
#   ggtitle("Engagement Ring Interest Starting 2012") +
#   theme_minimal() + 
#   theme(axis.text.x = element_text(angle = 90)) +
#   geom_line(aes(x=date, y=ma))


# * I DON'T KNOW IF I WILL USE MOVING AVERAGE
# * I DON'T LIKE LOSING DATA
# * AND DON'T KNOW WHAT TO DO WHEN I LACK IT IN DECOMP MODEL
# squeak <- engagement_sub %>% mutate(test=detrended-ma)
# ggplot(squeak, aes(x=date, y=test)) + 
#   geom_point(size=0.8, col="lightblue") + 
#   geom_line(alpha=0.5) +
#   scale_x_date(date_breaks="1 year", labels=date_format("%Y-%m")) +
#   ylab("google interest") +
#   xlab("") +
#   ggtitle("Engagement Ring Interest Starting 2012") +
#   theme_minimal() + 
#   theme(axis.text.x = element_text(angle = 90))



# * HARMONIC REGRESSION
# library(HarmonicRegression)
# h_fits <- harmonic.regression(inputts=engagement_sub$detrended,
#                               inputtime=as.numeric(engagement_sub$date))
# squeak$h_fit <- h_fits$fit.vals
# ggplot(squeak, aes(x=date, y=detrended)) + 
#   geom_point(size=0.8, col="lightblue") + 
#   geom_line(alpha=0.5) +
#   scale_x_date(date_breaks="1 year", labels=date_format("%Y-%m")) +
#   ylab("google interest") +
#   xlab("") +
#   ggtitle("Engagement Ring Interest Starting 2012") +
#   theme_minimal() + 
#   theme(axis.text.x = element_text(angle = 90)) +
#   geom_line(aes(x=date, y=h_fit))

library(TSA)
detrended_ts <- ts(engagement_sub$detrended, start=c(2012,1), frequency=12)
harm_val <- harmonic(detrended_ts, m=3)
harm_fit <- lm(detrended_ts~harm_val)

engagement_sub$fit_harm <- harm_fit$fitted.values
ggplot(engagement_sub, aes(x=date, y=detrended)) +
  geom_point(size=0.8, col="lightblue") +
  geom_line(alpha=0.2) +
  scale_x_date(date_breaks="1 year", labels=date_format("%Y-%m")) +
  ylab("google interest") +
  xlab("") +
  ggtitle("Engagement Ring Interest Starting 2012") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90)) +
  geom_line(aes(x=date, y=fit_harm), col="black", alpha=0.7)

engagement_sub <- engagement_sub %>% mutate(noise=detrended-fit_harm)
ggplot(engagement_sub, aes(x=date, y=noise)) +
  geom_point(size=0.8, col="lightblue") +
  geom_line(alpha=0.2) +
  scale_x_date(date_breaks="1 year", labels=date_format("%Y-%m")) +
  ylab("google interest") +
  xlab("") +
  ggtitle("Engagement Ring Interest Starting 2012") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90))


# * NOT SURE WHY WE EVEN BOTHER HERE BUT OK
# * SET MEAN TO 0
# * SOURCE: STA137
engagement_sub <- engagement_sub %>% mutate(mean0=noise-mean(noise))



# * TEST FOR STATIONARITY
# * STATIONARY?
# * https://rpubs.com/richkt/269797
d <- 12
n <- nrow(engagement_sub)

box_lag <- min(2*d, n/5)
Box.test(engagement_sub$mean0, lag=box_lag, type="Ljung-Box")

# library(tseries)
# adf.test(engagement_sub$mean0)

# kpss.test(engagement_sub$mean0, null="Trend")

# library(forecast)
# ggAcf(engagement_sub$mean0) +
#   theme_minimal()


# * https://machinelearningmastery.com/gentle-introduction-autocorrelation-partial-autocorrelation/
acf(engagement_sub %>% pull(mean0))

pacf(engagement_sub %>% pull(mean0))


# * PREDICT NEW VALUES

# * START WITH NON MEAN 0
append_dates_1  <- gsub("201[2-3]{1}", "2019", engagement_sub$date[5:12])
append_dates_2  <- gsub("201[2-3]{1}", "2020", engagement_sub$date[1:4])
append_dates    <- data.frame(date=as.Date(c(append_dates_1, append_dates_2)))




# * https://cran.r-project.org/web/packages/TSA/TSA.pdf

# * EXAMPLE FROM: http://people.stat.sc.edu/Hitchcock/stat520chapter9Rcode.txt
# Harmonic regression for Dubuque temperature data:
#   data(tempdub)
# har.=harmonic(tempdub,m=1) 
# model4=lm(tempdub~har.)
# summary(model4)
# 
# # predicting for June 1976:
# future.time = 1976.41667
# y.hat.pred = as.numeric(coef(model4) %*% c(1,cos(2*pi*future.time),sin(2*pi*future.time)) ); 
# print(y.hat.pred)

# * 88 VALUES IN THIS
# * THE NEXT VALUES WILL BE THE SAME AS THE "NEXT" 12
predict_harm <- engagement_sub$fit_harm[5:16]

predict_trend <- predict(new_poly, newdata=append_dates)

predict_search <- (predict_trend + predict_harm)^(1/lambda_1)

new_values <- cbind(date=append_dates, search=predict_search)

predict_df_classical <- engagement_sub %>% dplyr::select(date, search)
predict_df_classical <- rbind(predict_df_classical, new_values)
predict_df_classical <- cbind(predict_df_classical, type=c(rep("observed",88), rep("projected",12)))

ggplot(predict_df_classical, aes(x=date, y=search)) + 
  geom_point(size=0.8, aes(col=type)) + 
  geom_line(alpha=0.5) +
  scale_x_date(date_breaks="1 year", labels=date_format("%Y-%m")) +
  ylab("google interest") +
  xlab("") +
  ggtitle("Engagement Ring Interest Starting 2012") +
  theme_minimal() + 
  theme(axis.text.x = element_text(angle = 90))







# * HOW COULD WE HAVE DONE THIS WITH:
# * ARIMA MODELS???
# * https://towardsdatascience.com/unboxing-arima-models-1dc09d2746f8
# * SEE STEP 5 OF FOLLOWING SOURCE:
# * https://www.datascience.com/blog/introduction-to-forecasting-with-arima-in-r-learn-data-science-tutorials

library(forecast)
# ?auto.arima
arima_auto_fit <- auto.arima(engagement_sub %>% pull(search), stepwise=FALSE)
# tsdisplay(residuals(arima_auto_fit), lag.max=45, main='(1,1,1) Model Residuals')

# * LAG 17 IN ACF
# * BUT NO CLEAR PATTERNS
# * SO FORECAST

# fcast <- forecast(arima_auto_fit, h=12)
# plot(fcast)

# * https://stats.stackexchange.com/questions/378872/write-arima-model-from-auto-arima-output
# * https://otexts.com/fpp2/arima-r.html
# * https://stats.stackexchange.com/questions/306933/arima1-1-1-equation-based-on-r-output
# * https://www.slideshare.net/21_venkat/arima-26196965

arima_forecast <- forecast(arima_auto_fit, h=12)
append_dates_1  <- gsub("201[2-3]{1}", "2019", engagement_sub$date[5:12])
append_dates_2  <- gsub("201[2-3]{1}", "2020", engagement_sub$date[1:4])
forecast_df    <- data.frame(date=c(engagement_sub$date, as.Date(append_dates_1), as.Date(append_dates_2)),
                             search=c(engagement_sub$search, arima_forecast$mean),
                             type=c(rep("observed", nrow(engagement_sub)), rep("predicted",12)))
# * PLOT FOR 2012 ON
ggplot(forecast_df, aes(x=date, y=search)) + 
  geom_point(size=0.8, aes(color=type)) + 
  geom_line(alpha=0.5) +
  scale_x_date(date_breaks="1 year", labels=date_format("%Y-%m")) +
  ylab("google interest") +
  xlab("") +
  ggtitle("Engagement Ring Interest Starting 2012") +
  theme_minimal() + 
  theme(axis.text.x = element_text(angle = 90)) 
