#' @name 01_analyze_output.R
#' @title Webinar 1 Code for Analyzing MOVES Output data (June 5, 2023)
#' @author Timothy Fraser, PhD


# You'll need these packages loaded...

# Note: uncomment and install these first if you haven't already
# install.packages(c("DBI", "RMariaDB", "dplyr"))

library(DBI) # For Database/SQL intergration
library(RMariaDB) # For Connecting to MariaDB
library(dplyr) # For data wrangling
library(readr) # For reading/writing csvs
library(tidyr) # For pivoting

# We're going to write you a quick connect function to help you connect to databases...
connect = function(name){
  # Establish a database connection...
  conn = DBI::dbConnect(
    # Use this driver...
    drv = RMariaDB::MariaDB(),
    # By default, MOVES adds this connection for you.
    username = 'moves', password = 'moves',
    port = 3306, host = "localhost",
    # Name of Database to connect to!
    dbname = name)
  # Return the connection object as your output!
  return(conn)
}

# Connect to database CTECH!
db = connect("ctech")

# We can use a pipeline '%>%' from the dplyr package. It applies functions to objects quickly.

# Let's look at our metadata in 'movesruns'!
db %>% tbl("movesrun")

# Let's look at our emissions estimate output in 'movesoutput'
db %>% tbl("movesoutput")

# Let's look at our activity estimate output in 'movesactivityoutput'
db %>% tbl("movesactivityoutput")


# Some tricks:


# We could grab just the first two rows...
db %>% tbl("movesoutput") %>% head(2)

# We could select() just a few columns
db %>%
  tbl("movesoutput") %>%
  select(yearID, fuelTypeID, emissionQuant)

# We could select() and rename those columns
# We can also save a query as an object 'q' and keep working on it.
q = db %>%
  tbl("movesoutput") %>%
  select(year = yearID, fueltype = fuelTypeID, emissions = emissionQuant)

# We could filter() our data
q %>%
  filter(fueltype == 2 & year == 2023) # Just diesel vehicles in 2023

# We could aggregate our data! (and save it as q2
q2 = q %>%
  # For each year & fueltype pair...
  group_by(year, fueltype) %>%
  # Add up all the emissions, and ignore any NAs (non-applicable values)
  summarize(emissions = sum(emissions, na.rm = TRUE))

# Use this cheatsheet for translating IDs in MOVES
# https://github.com/USEPA/EPA_MOVES_Model/blob/master/docs/MOVES3CheatsheetOnroad.pdf


# Once we're happy with our query, we can collect() it, which actually runs the computation.
data = q2 %>% collect()

# Now, data is a real object in our environment!
data

# We can even quickly recode the values, using recode() from dplyr!

data2 = data %>%
  mutate(fueltype = fueltype %>% recode(
    "1" = "Gasoline",
    "2" = "Diesel",
    "3" = "CNG",
    "4" = "LPG",
    "5" = "E85",
    "9" = "Electricity"))

# We can save it to file!
data2 %>% write_csv("webinar1/emissions_by_fueltype.csv")


remove(data, data2, q, q2)



# In reality, we don't need all these columns,
# because most are blank,
# unless you run the most complex, disaggregated MOVES run ever.
# I recommend using dplyr's glimpse() to check your columns quickly.
db %>%
  # For emissions...
  tbl("movesoutput") %>%
 # Get first 5 rows..
  head() %>%
  # Tilt them on their side for easy viewing
  glimpse()

# Here are my shortcuts for working with moves data.

# So, we could actually select a set of variables first...
db %>%
  tbl("movesoutput") %>%
  select(
    run = MOVESRunID,
    year = yearID,
    county = countyID,
    pollutant = pollutantID,
    sourcetype = sourceTypeID,
    regclass = regClassID,
    fueltype = fuelTypeID,
    roadTypeID = roadTypeID,
    emission = emissionQuant)

# In fact, we could even use a trick...

# Make a named vector called myvars...
myvars = c(
  run = "MOVESRunID",
  year = "yearID",
  county = "countyID",
  pollutant = "pollutantID",
  sourcetype = "sourceTypeID",
  regclass = "regClassID",
  fueltype = "fuelTypeID",
  roadtype = "roadTypeID",
  emission = "emissionQuant",
  activitytype = "activityTypeID",
  activity = "activity")
# Let's view it!
myvars

# And use `any_of()` from `dplyr` to grab any columns matching that information from that table!
db %>% tbl("movesoutput") %>% select(any_of(myvars))


# Let's say we ONLY care about on-road emissions, so we'll cut off-network obs (roadtype == 1)
# Let's collect() the result!
e = db %>% tbl("movesoutput") %>% select(any_of(myvars)) %>% filter(roadtype != 1) %>% collect()
# Also works for movesactivityoutput, even though variables are different!
a = db %>% tbl("movesactivityoutput") %>% select(any_of(myvars)) %>% filter(roadtype != 1) %>% collect()

# View it!
e
# View it!
a


# But don't we **really** want to know
# BOTH the emissions and activity levels for a given unit of observation?

# We'll need to join this data together.

# What are our activity types?
a %>%
  select(activitytype) %>%
  distinct()

myactivity = c(
  "1" = "vmt",
  "3" = "idlehours",
  "4" = "sourcehours",
  "6" = "vehicles",
  "7" = "starts",
  "13" = "hoteld", # For Diesel Auxilary
  "14" = "hotelb", # For Battery or AC
  "15" = "hotelo" # For engines off
)
# Okay, let's recode them...
a %>% mutate(activitytype = activitytype %>% recode(!!!myactivity))


# VMT is recorded for every roadtype, but no other activity type is.
# So let's get just vmt activity...
a_road = a %>%
  mutate(activitytype = activitytype %>% recode(!!!myactivity)) %>%
  filter(activitytype == "vmt") %>%
  # Drop activity type, and just call activity 'vmt'
  select(-activitytype) %>% rename(vmt = activity)

# And let's join the result together!
output = e %>%
  left_join(by = c("run", "year", "county", "sourcetype", "regclass", "fueltype", "roadtype"),
            y = a_road)

# Let's write it to iile.
output %>% write_csv("webinar1/joined_data.csv")


# Always extremely important to disconnect.
dbDisconnect(db)

