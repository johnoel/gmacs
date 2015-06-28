---
title: "Gmacs Example Stock Assessment"
author: "The Gmacs development team"
date: "June 2015"
output:
  pdf_document:
    highlight: zenburn
    toc: yes
  html_document:
    theme: flatly
    toc: yes
  word_document: default
bibliography: Gmacs.bib
---






# Introduction

Gmacs is a generalized size-structured stock assessment modelling framework for
molting crustacean species. Gmacs can make use of a wide variety of data,
including fishery- and survey-based size-composition data, and fishery-dependent
and -independent indices of abundance. Gmacs is coded using AD Model Builder.

Crab stocks of Alaska are managed by the North Pacific Fisheries Management
Council ([NPFMC](http://npfmc.org)). Some stocks are assessed with integrated
size-structured assessment models of the form described in
@punt_review_2013. Currenlty, each stock is assessed using a stock-specific
assessment model (e.g. @zheng_bristol_2014). The Gmacs project aims to provide
software that will allow each stock to be assessed inside a single modelling
framework.

Gmacs is used here to develop an assessment model for the Bristol Bay Red King
Crab (BBRKC) stock. This document serves as a test-case for the development of
Gmacs. The example assessment is intended to match closely with a model scenario
presented to the Spring 2014 BSAI Crab Plan Team Meeting by @zheng_bristol_2014.
The following summarizes the outcome of some comparisons between the existing
BBRKC stock assessment model [@zheng_bristol_2014] and an emulated version using
the Gmacs platform.

An important component of the Gmacs framework is the provision of software for
plotting Gmacs model outputs. In what follows, we demonstrate the use of the
`gmr` package to process the output of the Gmacs-BBRKC model and produce plots
that can be used in assessment reports.

Together, the Gmacs-BBRKC model and this report serve as the first example of
what should follow for other crab stocks: that is, direct model comparisons to
(1) test the efficacy of Gmacs, and (2) determine whether Gmacs can be used in
practice to closely match the outputs of existing ADFG stock assessment models.


## Summary of analytical approach

To reduce annual measurement errors associated with abundance estimates derived
from the area-swept method, the ADFG developed a length-based analysis (LBA) in
1994 that incorporates multiple years of data and multiple data sources in the
estimation procedure (Zheng et al. 1995a). Annual abundance estimates of the
BBRKC stock from the LBA have been used to manage the directed crab fishery and
to set crab bycatch limits in the groundfish fisheries since 1995. An
alternative LBA (research model) was developed in 2004 to include small size
groups for federal overfishing limits. The crab abundance declined sharply
during the early 1980s. The LBA estimated natural mortality for different
periods of years, whereas the research model estimated additional mortality
beyond a basic constant natural mortality during 1976-1993.

The original LBA model was described in detail by Zheng et al. (1995a, 1995b)
and Zheng and Kruse (2002). The model combines multiple sources of survey,
catch, and bycatch data using a maximum likelihood approach to estimate
abundance, recruitment, catchabilities, catches, and bycatch of the commercial
pot fisheries and groundfish trawl fisheries.

Critical assumptions of the model include:

  * The base natural mortality is constant over shell condition and size and was
    estimated assuming a maximum age of 25 and applying the 1% rule (Zheng
    2005).
  * Survey and fisheries selectivities are a function of size and were constant
    over shell condition.  Selectivities are a function of sex except for trawl
    bycatch selectivities, which are the same for both sexes. Two different
    survey selectivities were estimated: (1) 1975-1981 and (2) 1982-2013 based
    on modifications to the trawl gear used in the assessment survey.
  * Growth is a function of size and did not change over time for males. For
    females, three growth increments per molt as a function of size were
    estimated based on sizes at maturity (1975-1982, 1983-1993, and
    1994-2013). Once mature, female red king crabs grow with a much smaller
    growth increment per molt.
  * Molting probabilities are an inverse logistic function of size for
    males. Females molt annually.
  * Annual fishing seasons for the directed fishery are short.
  * Survey catchability ($q$) was estimated to be 0.896, based on a trawl
    experiment by Weinberg et al. (2004) with a standard deviation
    of 0.025. Survey catchability was assumed to be constant over time. Some
    scenarios estimate $q$ in the model.
  * Males mature at sizes =120 mm CL. For convenience, female abundance was
    summarized at sizes =90 mm CL as an index of mature females.  viii. For
    summer trawl survey data, shell ages of newshell crabs were 12 months or
    less, and shell ages of oldshell and very oldshell crabs were more than 12
    months.
  * Measurement errors were assumed to be normally distributed for size
    compositions and were log- normally distributed for biomasses.


# Gmacs

The data and model specifications used in the Gmacs-BBRKC model are very similar
to those used in the '4nb' scenario developed by @zheng_bristol_2014, herein
referred to as the ADFG-BBRKC model.

Since the BBRKC model from @zheng_bristol_2014 treats recruits by sex along with
sex-specific natural mortality and fishing mortality, results from the male
components are compared with results from a Gmacs model implementation tuned to
male-only data.

Parameter Number of estimated parameters Value Natural mortality 1 Males
(1980-84) 1 Females (1980-84) 1 Females (1976-79; 1984-1993) 0.18 yr-1 Other
years

Growth
Transition matrix Pre-specified Molt probability (slope and intercept) (1975-78)
Females? 2 Molt probability (slope and intercept) (1979+) Females? 2 Molt
probability (slope and intercept) Males? Pre-specified

Recruitment
Gamma distribution parameters 4 Annual deviations ??

Fishing mortality
Mean fishing mortality (directed fishery) 1 Annual fishery deviations (directed fishery) ??
Mean fishing mortality (groundfish fishery) 1 Annual fishery deviations (groundfish fishery) ??
Mean fishing mortality (Tanner fishery) 1 Annual fishery deviations (Tanner fishery) ??

Fishery selectivity
Directed fishery slope and intercept (by sex) 4 Groundfishery slope and intercept (both sexes) 2 Tanner crab
fishery slope and intercept (both sexes) 4 Retention
Slope, inflection point, asymptote 3 Initial conditions ??
Survey catchability 1 Survey selectivity
NMFS Slope and intercept (1975-81) by sex 4 NMFS Slope and intercept (1982+) by sex 4 BSFRF selectivity
Pre-specified BSFRF CV 1


# Population Dynamics

Comparison tables of two different model approaches could be done by

Specification       | Parameter | ADFG Value | Gmacs OneSex | Gmacs TwoSex |
------------------- | --------- | ---------- | ------------ | ------------ |
Start year          | $t=0$     | 1975       | 1953         | 1975         |
End year            | $t=T$     | 2014       | 2014         | 2014         |
No. sexes           | $s$       | 2          | 1            | 2            |
No. shell condition | $\nu$     | 2          | 2            | 2            |
No. maturity        | $m$       | 2          | 1            | 1            |
No. size-classes    | $\ell$    | 20         | 20           | 20           |


Life History Trait  | Parameter | ADFG Value | Gmacs Value | Comments
------------------  | --------- | ---------- | ----------- | --------
Natural Mortality   | M         | Fixed      | Fixed       | M is fixed in both models


# Fishery Dynamics

Specification       | Parameter | ADFG Value | Gmacs Value | Comments
------------------  | --------- | ---------- | ----------- | --------
No. Fleets          |           | 5          | 2           |
No. Fleets          |           | 5          | 5           |



## File Description

  * The `*.tpl` file is working, it builds and the `*.exe` file runs successfully.
  * The main `*.dat` file is read in as expected (comments within).
  * There is a second data file `rksize13s.dat` with sample sizes for 
    various rows of size-comp data. See lines 81-87 of `*.tpl`. 
  * Input sample sizes appear to be capped to the constant numbers entered in 
    the main data file under 'number of samples' or 'sample sizes' (variously).
  * There is a third data file `tc7513s.dat` specifically for data from the
    tanner crab fishery (with red crab bycatch).
  * There is a standard control file `*.ctl` with internal comments.
  * There is an excel spreadsheet which can be used to read in the model
    output files and display related plots (it's a bit clunky).
  * There are two batch files in the model directory: `clean.bat` and `scratch.bat`.
    The 'clean' batch file deletes files related to a single model run. The
    'scratch' batch file deletes all files relating to the model build and 
    leaves only source and data files.



# Comparison of model results

The following plots summarize plots made using `gmr` based on output from
@zheng_bristol_2014 and Gmacs. Two Gmacs models are provided, the OneSex model
and the TwoSex model.


## Fit to survey abundance indices

The model fit to survey biomass for males was better for the @zheng_bristol_2014
model (at least visually) than for either of the current implementations of
Gmacs (Figure \ref{fig:survey_biomass}).

![Model fits to NMFS trawl survey biomass.\label{fig:survey_biomass}](figure/survey_biomass-1.png) 


## Estimated retained catch and discards

The observed and predicted catches by gear type are summarized in (Figure
\ref{fig:fit_to_catch}). Data for discard fisheries were read in with 100%
mortality (as clarified in Table 1 of @zheng_bristol_2014).

![Observed and predicted catch by gear type for the Gmacs models.\label{fig:fit_to_catch}](figure/fit_to_catch-1.png) 


## Fit to size composition data

The fit of the Gmacs models to the BBRKC size composition data are given in the
following plots. These include fits to the directed pot fishery for males
(Figure \ref{fig:sc_pot_m}), male crabs discarded in the directed pot fishery
(Figure \ref{fig:sc_pot_discarded_m}), female crabs discarded in the directed
pot fishery (Figure \ref{fig:sc_pot_discarded_f}), the groundfish trawl bycatch
fisheries for males (Figure \ref{fig:sc_trawl_bycatch_m}) and females (Figure
\ref{fig:sc_trawl_bycatch_f}), and the NMFS trawl survey (Figure
\ref{fig:sc_NMFS_m}).

![Observed and model estimated length-frequencies of male BBRKC by year retained in the directed pot fishery.\label{fig:sc_pot_m}](figure/sc_pot_m-1.png) 

![Observed and model estimated length-frequencies of male BBRKC by year discarded in the directed pot fishery.\label{fig:sc_pot_discarded_m}](figure/sc_pot_discarded_m-1.png) 

![Observed and model estimated length-frequencies of female BBRKC by year discarded in the directed pot fishery.\label{fig:sc_pot_discarded_f}](figure/sc_pot_discarded_f-1.png) 

![Observed and model estimated length-frequencies of male BBRKC by year in the groundfish trawl bycatch fisheries.\label{fig:sc_trawl_bycatch_m}](figure/sc_trawl_bycatch_m-1.png) 

![Observed and model estimated length-frequencies of female BBRKC by year in the groundfish trawl bycatch fisheries.\label{fig:sc_trawl_bycatch_f}](figure/sc_trawl_bycatch_f-1.png) 

![Observed and model estimated length-frequencies of male BBRKC by year in the NMFS trawl fishery.\label{fig:sc_NMFS_m}](figure/sc_NMFS_m-1.png) 


## Mean weight-at-length

The mean weight-at-length ($w_\ell$) of crabs is defined in kg and the carapace
length ($\ell$, CL) in mm. The mean weight-at-length of males used in all models
is nearly identical. The only difference between the Gmacs models and Zheng's is
in the final length class (160mm) where the mean weight is greater in Zheng's
model than in Gmacs (Figure \ref{fig:length-weight}). However, the pattern is
very different for females. This difference is due to...

![Relationship between carapace length (mm) and weight (kg) by sex in each of the models.\label{fig:length-weight}](figure/length_weight-1.png) 


## Initial recruitment size distribution

Gmacs was configured to match the @zheng_bristol_2014 model recruitment size
distribution closely (Figure \ref{fig:init_rec}).

![Distribution of carapace length (mm) at recruitment.\label{fig:init_rec}](figure/init_rec-1.png) 


## Molting increment and probability

Options to fit relationship based on data was developed but for the BBRKC
system, a size-specific vector was used to determine molt increments as shown
below (Figure \ref{fig:growth_inc}). Fixed parameters in gmacs were set to
represent that assumed from @zheng_bristol_2014 (Figure \ref{fig:molt_prob}).

![Growth increment (mm).\label{fig:growth_inc}](figure/growth_inc-1.png) 

![Molting probability.\label{fig:molt_prob}](figure/molt_prob-1.png) 


## Transition processes

The first set of figures is the growth probabilities (for all crabs that molt)
(Figure \ref{fig:growth_trans}). The second set of figures is the combination of
growth and molting and represents the size transition (Figure
\ref{fig:size_trans}).

![Growth transitions.\label{fig:growth_trans}](figure/growth_trans-1.png) 

![Size transitions.\label{fig:size_trans}](figure/size_trans-1.png) 


## Numbers at length in 1975 and 2014

The number of crabs in each size class (${\bf n}$) in the initial year ($t=1$)
and final year ($t=T$) in each model differ substantially (Figure
\ref{fig:init_N}). The scale of these results differ significantly and may be
related to the interaction with natural mortality estimates and how the initial
population-at-lengths were established (the BBRKC model assumes all new-shell).

![Numbers at length in 1975.\label{fig:init_N}](figure/init_N-1.png) 


## Selectivity

The selectivity by length ($S_\ell$) for each of the fisheries (Figure
\ref{fig:selectivity}).

![Estimated selectivity functions.\label{fig:selectivity}](figure/selectivity-1.png) 


## Natural mortality

The figure below illustrates implementation of four step changes in $M_t$
(freely estimated) in gmacs relative to the estimates from Zheng et al. 2014
(Figure \ref{fig:M_t}). In both the ADFG-BBRKC and Gmacs-BBRKC models,
time-varying natural mortality ($M_t$) is freely estimated with four step
changes through time. The years ($t$) that each of these steps cover are fixed a
priori. The pattern in time-varying natural mortality is resonably similar
between the two models (Figure \ref{fig:M_t}), however the peak in natural
mortality during the early 1980 is not as high in the Gmacs-BBRKC model.

![Time-varying natural mortality ($M_t$).\label{fig:M_t}](figure/natural_mortality-1.png) 


## Recruitment

Recruitment patterns are similar, but differences in natural mortality
schedules will affect these matches. The figure below plots the values to have
the same mean (Figure \ref{fig:recruitment}). Patterns in recruitment through
time ($R_t$) estimated in the two models are similar, but differences in
natural mortality schedules will affect these matches (Figure
\ref{fig:recruitment}).

![Estimated recruitment time series ($R_t$).\label{fig:recruitment}](figure/recruitment-1.png) 


## Mature male biomass (MMB)

The spawning stock biomass of mature males, termed the mature male biomass
($\mathit{MMB}_t$), also differs a lot bewteen the two models (Figure
\ref{fig:ssb}).

![Mature male biomass (MMB) predicted in the two versions of the Gmacs model (OneSex and TwoSex) and the Zheng model.\label{fig:ssb}](figure/spawning_stock_biomass-1.png) 


## Comparison of model results

The results of the ADFG-BBRKC model are compared here to the results of the
Gmacs-BBRKC model.

Model           | FSPR | BSPR     | FOFL | OFL     | RSPR
--------------- | ----:| --------:| ----:| -------:| --------:
Gmacs (one sex) | 0.28 | 32995.95 | 0.28 | 3373.93 | 8160.40
Gmacs (two sex) | 0.21 | 22205.54 | 0.21 | 3030.39 | 16959.09


### Gmacs results

We need to be able to produce a table of the comparative likelihoods (by
component) of the alternative models. For best practice, just try and do what we
do with SS models for SESSF stocks anyway. See the pink link report, and enter a
section for each of those, and see if we can emulate a report of that type.


# Discussion

Comparisons of actual likelihood function values and year-specific fits using
the robust-multinomial would be the next step after selectivity issues are
resolved. Subsequent to that, it would be worth exploring aspects of alternative
model specifications (e.g., constant natural mortality over time, time-varying
selectivity, etc) to evaluate sensitivities.

This discussion will focus on the challenges in developing a Gmacs version of
the BBRKC model: those met, and those yet to be met.


# References