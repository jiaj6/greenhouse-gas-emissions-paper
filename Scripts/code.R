### Preamble ###
# Purpose: explore the effects of electricity consumption and natural gas consumption on GHG emissions
# Author: Jia Jia Ji
# Email: jiajia.ji@mail.utoronto.ca
# Date: Jan.24, 2021
# Issues:
# To do: get the data, clean the data, do exploratory analysis and apply linear regression models to data


### install and load the packages ###
library(tidyverse)
library(ggplot2)
library(emmeans)

# install.packages('opendatatoronto')
library(opendatatoronto)

### R and R packages citations ###
citation()
citation('tidyverse')
citation('ggplot2')
citation('emmeans')
citation('opendatatoronto')


# get the data from Open Data Toronto
energy_GHG <- opendatatoronto::search_packages('Annual Energy Consumption') %>%
  opendatatoronto::list_package_resources() %>%
  filter(name == 'annual-energy-consumption-data-2018') %>% 
  # we are interested in the data in 2018
  select(id) %>%
  opendatatoronto::get_resource()

# write the raw data in a csv file and put it in the input folder
#write_csv(energy_GHG, "Inputs/raw_data.csv")

# since this csv file has several heading and subheading lines, 
# we simply skip these lines, select those columns/variables relevant to our research question and read these data in
# the selected columns: Operation_Type, City, Total_Floor_Area, Avg_hrs/wk, Electricity, Natural_Gas, GHG_Emissions
# also convert the numerical variables from factors to integers/numerical values 
operation_type <- energy_GHG[8:1490, 2]
city_class <- energy_GHG[8:1490, 4]
total_floor_area <- energy_GHG[8:1490, 6]
avg_weekly_hrs <- energy_GHG[8:1490, 8]
electricity <- energy_GHG[8:1490, 10]
natural_gas <- energy_GHG[8:1490, 12]
GHG_emissions <- energy_GHG[8:1490, 32]

# then create a dataframe consisting of these variables
# the dataframe has 7 columns and 1483 rows
energy_GHG_df <- data.frame(operation_type, city_class, total_floor_area, avg_weekly_hrs, electricity, natural_gas, GHG_emissions)


### data cleaning ###

# row 1463 is an empty row, so drop the entire row
energy_GHG_df <- energy_GHG_df[-1463, ]
# row 1: the values for electricity consumption, natural gas consumption and GHG emissions are missing, 
# here, we drop the nul values (few missing values)
energy_GHG_df <- energy_GHG_df[-1, ]
# check if there are other missing values
colSums(is.na(energy_GHG_df)) # no missing value

# also the values of city_class are 0 for row 386, 393 and 395, drop these unreasonable values
energy_GHG_df <- energy_GHG_df[-c(386, 393, 395),]

# convert the numeric variables from character type to numeric type
total_floor_area_1 <- as.integer(gsub(",", "", energy_GHG_df[, 3]))
electricity_1 <- as.numeric(energy_GHG_df[, 5])
natural_gas_1 <- as.numeric(energy_GHG_df[, 6])
GHG_emissions_1 <- as.integer(gsub(",", "", energy_GHG_df[, 7]))
# also rename the categorical variables in clean dataframe
operation_type_1 <- energy_GHG_df[, 1]
city_class_1 <- energy_GHG_df[, 2]
avg_weekly_hrs_1 <- energy_GHG_df[,4]

# create a new dataframe consisting of the variables with appropriate types
clean_energy_GHG_df <- data.frame(operation_type_1, city_class_1, total_floor_area_1, avg_weekly_hrs_1, electricity_1, natural_gas_1, GHG_emissions_1)

# add column names in the dataframe
colnames(clean_energy_GHG_df)[1] <- 'operation_type'
colnames(clean_energy_GHG_df)[2] <- 'city_class'
colnames(clean_energy_GHG_df)[3] <- 'total_floor_area'
colnames(clean_energy_GHG_df)[4] <- 'avg_weekly_hrs'
colnames(clean_energy_GHG_df)[5] <- 'electricity'
colnames(clean_energy_GHG_df)[6] <- 'natural_gas'
colnames(clean_energy_GHG_df)[7] <- 'GHG_emissions'
clean_energy_GHG_df


### data overview ###

# operation_type: nominal variable: 26 different levels

# city_class: nominal variable: 11 levels

# total_floor_area: continuous variable 
# check the range: [0, 23073615]
min(clean_energy_GHG_df$total_floor_area)
max(clean_energy_GHG_df$total_floor_area)

# avg_weekly_hrs: ordinal variable: 3 levels

# electricity, natural_gas: continuous variables
# check the range for electricity: [0, 131780414]
min(clean_energy_GHG_df$electricity)
max(clean_energy_GHG_df$electricity)

# check the range for natural_gas: [0, 6940806]
min(clean_energy_GHG_df$natural_gas)
max(clean_energy_GHG_df$natural_gas)

# GHG_emissions: discrete variable
# check the range: [0, 18193619]
min(clean_energy_GHG_df$GHG_emissions)
max(clean_energy_GHG_df$GHG_emissions)


### plots & summary statistics ###

# data summary table of all selected numerical variables
emission_sum <- summary(GHG_emissions_1)
electricity_sum <- summary(electricity_1)
natural_gas_sum <- summary(natural_gas_1)
floor_area_sum <- summary(total_floor_area_1)

summary <- matrix(c(emission_sum, electricity_sum, natural_gas_sum, floor_area_sum), ncol= 6, byrow=TRUE)
summary_table <- as.table(summary)
colnames(summary_table) <- c('Min', 'Q1', 'Median', 'Mean', 'Q3', 'Max')
rownames(summary_table) <- c('GHG emissions', 'Electricity consumption', 'Natural gas consumption', 'Total floor area')
summary_table %>%
  knitr::kable(caption = 'The data summary table for GHG Emissions, Electricity Consumption, Natural Gas Consumption and Total Floor Area',
               col.names = c('Min', 'Q1', 'Median', 'Mean', 'Q3', 'Max'),
               align = c('l', 'l', 'l', 'l', 'l', 'l')) 

# scatter plot of electricity consumption (independent variable) vs GHG_emissions (dependent variable)
clean_energy_GHG_df %>%
  ggplot(mapping = aes(x = electricity, y = GHG_emissions)) + 
  geom_point() +   # scatter plot
  xlim(0, 5000000) + ylim(0, 500000) +   # set xlim, ylim to observe the general pattern more clearly (since there are few extreme values)
  geom_smooth(method = lm, color = 'red') +    # add the best fit 
  xlab('Electricity consumption (kWh)') + ylab('GHG emissions (Kg)') +
  ggtitle('The scatter plot between electricity consumption \nand greenhouse gas emissions') +
  theme_minimal() 


# scatter plot of natural gas consumption (independent variable) vs GHG_emissions (dependent variable)
clean_energy_GHG_df %>%
  ggplot(mapping = aes(x = natural_gas, y = GHG_emissions)) + 
  geom_point() +    # scatter plot
  xlim(0, 600000) + ylim(0, 1500000) +   # set xlim, ylim to observe the general pattern more clearly (since there are few extreme values)
  geom_smooth(method = lm, color = 'red') +    # add the best fit
  xlab('Natural gas consumption (kWh)') + ylab('GHG emissions (Kg)') +
  ggtitle('The scatter plot between natural gas consumption \nand greenhouse gas emissions') +
  theme_minimal()


# bar chart of operation_type (independent variable) vs GHG_emissions (dependent variable)
emission_type <- clean_energy_GHG_df %>%
  group_by(operation_type) %>%    # group by the different levels of operation type
  select(operation_type, GHG_emissions) %>%   
  summarise(emission_mean_by_type = mean(GHG_emissions))  # compute the average of GHG emissions by group

emission_type %>%
  ggplot(mapping = aes(x = operation_type, y = emission_mean_by_type, fill = operation_type)) + 
  geom_bar(stat = 'identity') +   # bar chart
  xlab('Operation type') + ylab('GHG emissions (Kg)') +
  ggtitle('The average greenhouse gas emissions\n for each operation type') +
  theme(legend.position = 'none', axis.text=element_text(size=8)) +
  coord_flip()  


# bar chart of city_class (independent variable) vs GHG_emissions (dependent variable)
emissions_city <- clean_energy_GHG_df %>%
  group_by(city_class) %>%    # group by the different levels of city 
  select(city_class, GHG_emissions) %>%
  summarise(emission_mean_by_city = mean(GHG_emissions))   ## compute the average of GHG emissions by group

emissions_city %>%
  ggplot(mapping = aes(x = city_class, y = emission_mean_by_city, fill=city_class)) + 
  geom_bar(stat = 'identity', position = 'dodge') +    # bar chart
  xlab('City classification') + ylab('GHG emissions (Kg)') +
  ggtitle('The average greenhouse gas emissions for \neach municipality where sites are located') +
  theme(axis.text.x=element_text(angle = 45, hjust = 1), legend.position = 'none')


### models ###

# Model 1: the multiple linear regression model including electricity and natural gas consumption as explanatory variables
# and total floor area and average weekly operating hours as the confounding variables
model_1 <- lm(GHG_emissions ~ electricity + natural_gas + total_floor_area + avg_weekly_hrs, data = clean_energy_GHG_df)
knitr::kable(summary(model_1)$coef, caption = 'The table of the estimates for fitted Model 1') 
# shows the results: estimates, p-values


# Model 2: the linear regression model with effects of operation type and city 
model_2 <- lm(GHG_emissions ~ electricity + natural_gas + operation_type + city_class + total_floor_area + avg_weekly_hrs,
              data = clean_energy_GHG_df)
knitr::kable(anova(model_2), digits = 3) # anova table
knitr::kable(summary(emmeans(model_2, ~operation_type))[c(1,2)], caption = 'The table of estimated marginal means for each operation type') # estimated marginal means for each operation type (only need the emmean column)


# check assumptions: errors are normally distributed and have constant variance
errors<-residuals(model_1)
yhat<-fitted(model_1)
par(mfrow = c(1,2))
# scatter plot of errors: no pattern, so constant variance
plot(errors, main='The scatter plot of errors')
abline(0,0)
# qq plot of errors: most points are near/on qq line, so errors follow normal distribution
qqnorm(errors)
qqline(errors)
