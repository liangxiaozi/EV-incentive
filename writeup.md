DAP II Final Project
================

Mikaela Lin: mikirin0307

Xiao Liang: liangxiaozi

1. Motivation and Research Question

U.S. states fund most of their road and infrastructure budgets with revenues from gasoline taxes. The more people use public roads, the more gasoline they consume, making the gas tax a well-designed user fee. As the market share of electric vehicles (EVs) on the road grows, however, the gas tax’s ability to fund road projects and decrease traffic congestion erodes. Both federal and state real tax revenue per vehicle mile traveled has been on a steady decline for decades, creating a fiscal gap for road expenditures even as the demand for road infrastructure improvements has grown. EVs produce lower emissions than traditional combustible-engine vehicles. Combining the fiscal gap with a desire to incentivize lower-emission vehicles, both federal government and states have responded with a variety of tax policies.

Li et al. find that the federal income tax credit of up to $7,500 for EV buyers contributed to about 40% of EV sales during 2011–13, with feedback loops explaining 40% of that increase (2017). On the state level, the policy incentive is more diverse: 19 states offer an additional incentive beyond the federal credit. 24 states impose a higher annual vehicle registration fee for EVs and some hybrid vehicles to help offset forgone gas tax revenue. 5 states offer both an incentive for the purchase of an EV and impose a higher registration fee for EVs than for combustible-engine vehicles. 

We would like to expand the study onto how policy incentive affects the EV numbers of registration on the state level.

2. Methods

2.1 Data Wrangling

Three data sets are primarily used in the research: 1) light-Duty vehicle registration, providing EV number and percentage as dependent variable, 2) state EV tax credits and registration fees, providing policy incentive on EV as independent variable, and 3) state annual summary economic statistics, providing control variables like consumer spending and price indexes. When computing the policy incentive, one concern is raised that the tax credit is a lump-sum benefit while the registration fee is annually required. According to the Bureau of Transportation Statistics, the average age of light vehicles in US is 12.5 years, so we use it as the standard magnifying power of registration fee. In this sense, we calculate the total incentive by: Total incentive = Tax credit - 12.5 * Registration fee.

2.2 Plotting

We take a two-pronged approach to addressing the visual disparity between the patterns of tax benefit and adoption rates. First, we create choropleth maps that visually portray the distribution of clean car tax advantages and the percentage of clean vehicles by state, using the color gradient to indicate varying levels of value. Secondly, we create two Shiny application to enable user-driven searches and dynamic data exploration. With the help of these applications, users may easily view the time trend of a specific vehicle type's quantity or percentage, filter states according to various tax incentives, and learn about their respective adoption rates. 

2.3 Text Processing

In text processing, we dive into extra text data scrapped from California regulations on vehicle registration and titling. We would like to study the sentiment, dependent frequency and cooccurrence for EV. However, in the California regulations, EV is referred to as "clean air vehicle". For convenience, we only focus on the word "clean" as a proxy for the EV term, to which text processing methods are applied.

2.4 OLS Regression

We emply three OLS models to refine our understanding. The base model assesses the direct effect of hybrid and electric vehicle (EV) incentives on clean vehicle adoption. Subsequently, we introduce state fixed effects in the second model to control for unobserved heterogeneity across states. In our third model, we incorporate macroeconomic indicators such as regional price parities and real per capita personal consumption expenditures. This inclusion aims to address potential omitted variable bias that might distort the estimated effects of tax incentives on clean vehicle adoption. To ensure our model is not compromised by multicollinearity, we conduct a preliminary analysis using a correlation heatmap, guiding the selection of economic indicators for the final regression model. 


3. Results

3.1 Plotting

Our visual analysis demonstrates that while there is a push towards clean vehicles, evidenced by the tax benefits and adoption rates, the effectiveness of incentives shows a complex picture with no clear-cut relationship. For instance, certain states outperform others in clean vehicle percentages despite lower or negative tax benefits, highlighting that additional factors beyond financial incentives may drive adoption rates.

3.2 Text processing

Through AFINN sentiment analysis, we find out that the overall sentiment in the text is -0.2785, while the sentiment with dependency on EV is 0.7619. This may indicate that the legal texts take a more positive attitudes towards EV registration than the overall vehicle registration.

The frequency bigram indiates that words like "certificate" and "decal" have high dependent frequency in terms of EV. This may reveal that most sub-articles are provided to grant certificate or decal to EV so that they may enjoy benefits like using High Occupancy Vehicle (HOV, or carpool) lanes

The cooccurrence table display similar results with the frequency bigram that "decal" has a extremely high probability (0.8357) of cooccurrence with "clean". It ranks the second just after "air" (0.9754).

3.3 OLS Regression

When comparing the three regression models, we find significant variations in the link between tax incentives and clean vehicle adoption rates. Despite the  low R-squared value at about 0.1, the unexpectedly negative effect of EV incentives in Model 1 raises the possibility that adoption of clean vehicles may be driven by reasons other than direct financial incentives. 

Consequently, we create Model 2, which has state fixed effects. The correlation between the adoption of clean vehicles and EV subsidies turns positive as the R-squared value rises noticeably. This change in the explanatory power of the model and the direction of the effect of the EV incentives indicate that the efficacy of financial incentives is significantly influenced by state-level conditions. 

Model 3 introduces economic controls to the regression, aiming to mitigate omitted variable bias and capture the broader economic context's influence on adoption rates. To make sure the chosen economic indicators don't show significant multicollinearity, a correlation heatmap was made for variable selection. The model suggests that the direct impact of incentives is less prominent when economic considerations are taken into account, seeing the diminishing significance of incentives. The adoption process is complicated, as evidenced by the negative coefficient for regional pricing parities and the positive correlation with real per capita PCE. 


4. Conclusion

Our analysis of how tax benefits affect the number of electric vehicle (EV) registrations in different states shows a complex link that goes beyond only financial incentive. The analysis highlights the intricate interactions between governmental incentives, economic factors, and state-specific conditions that influence the adoption of clean vehicles. It encompasses visual, textual, and statistical approaches. Both visual presentations and regression models cast doubt on the original theory that offering financial incentives would result in a direct increase in EV adoption. Instead, we find that the efficacy of these incentives is strongly mediated by regional economic environments and consumer behavior.


5. Bibliography

S. Li, L. Tong, J. Xing & Y. Zhou (2017). The Market for Electric Vehicles: Indirect Network Effects and Policy Design. Journal of the Association of Environmental and Resource Economists, 4(1), pp.89-133.