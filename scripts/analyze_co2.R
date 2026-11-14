# Set target country
country_code <- "COL"
country_name <- "Colombia"

# Create project directories if they do not exist
for (folder in c("scripts", "data", "figures", "results")) {
  dir.create(folder, showWarnings = FALSE, recursive = TRUE)
}

# Download OWID CO2 dataset if not already downloaded locally
raw_file <- "data/owid-co2-data.csv"
if (!file.exists(raw_file)) {
  url <- "https://raw.githubusercontent.com/owid/co2-data/master/owid-co2-data.csv"
  download.file(url, destfile = raw_file, mode = "wb")
}

# Load dataset and filter for Colombia
co2_data <- read.csv(raw_file, stringsAsFactors = FALSE)
country_data <- subset(co2_data, iso_code == country_code, 
                       select = c(year, co2, co2_per_capita))

# Keep valid years with non-missing CO2 values from 1990 onward
valid_co2 <- subset(country_data, !is.na(co2) & year >= 1990)
valid_co2 <- valid_co2[order(valid_co2$year), ]

# Save country-specific filtered dataset
country_csv <- paste0("data/", country_code, "_co2.csv")
write.csv(valid_co2, country_csv, row.names = FALSE)

# Calculate yearly percentage changes
valid_co2$annual_pct_change <- c(NA, diff(valid_co2$co2) / head(valid_co2$co2, -1) * 100)
yearly_changes_csv <- paste0("results/", country_code, "_yearly_changes.csv")
write.csv(valid_co2, yearly_changes_csv, row.names = FALSE)

# Calculate key summary metrics
start_year <- min(valid_co2$year)
end_year <- max(valid_co2$year)
start_co2 <- valid_co2$co2[valid_co2$year == start_year]
end_co2 <- valid_co2$co2[valid_co2$year == end_year]
endpoint_change <- ((end_co2 - start_co2) / start_co2) * 100

peak_idx <- which.max(valid_co2$co2)
peak_year <- valid_co2$year[peak_idx]
peak_co2 <- valid_co2$co2[peak_idx]
latest_per_capita <- tail(na.omit(valid_co2$co2_per_capita), 1)

summary_df <- data.frame(
  country = country_name,
  iso_code = country_code,
  start_year = start_year,
  end_year = end_year,
  start_co2_mt = round(start_co2, 2),
  end_co2_mt = round(end_co2, 2),
  endpoint_pct_change = round(endpoint_change, 2),
  peak_year = peak_year,
  peak_co2_mt = round(peak_co2, 2),
  latest_per_capita_t = round(latest_per_capita, 2)
)

summary_csv <- paste0("results/", country_code, "_summary.csv")
write.csv(summary_df, summary_csv, row.names = FALSE)

# Generate Figure 1: Annual CO2 Emissions
png(paste0("figures/", country_code, "_annual_co2.png"), width = 800, height = 500)
plot(valid_co2$year, valid_co2$co2, type = "l", col = "darkblue", lwd = 2,
     main = paste("Annual CO2 Emissions:", country_name),
     xlab = "Year", ylab = "CO2 Emissions (Million Tonnes)")
grid()
dev.off()

# Generate Figure 2: Per-Capita CO2 Emissions
png(paste0("figures/", country_code, "_per_capita.png"), width = 800, height = 500)
plot(valid_co2$year, valid_co2$co2_per_capita, type = "l", col = "darkgreen", lwd = 2,
     main = paste("Per-Capita CO2 Emissions:", country_name),
     xlab = "Year", ylab = "CO2 per Capita (Tonnes / Person)")
grid()
dev.off()

# Generate Figure 3: Annual Percentage Change
png(paste0("figures/", country_code, "_annual_change.png"), width = 800, height = 500)
barplot(valid_co2$annual_pct_change, names.arg = valid_co2$year,
        col = ifelse(valid_co2$annual_pct_change >= 0, "firebrick", "steelblue"),
        main = paste("Annual Percentage Change in CO2 Emissions:", country_name),
        xlab = "Year", ylab = "Annual Change (%)", las = 2, cex.names = 0.7)
abline(h = 0, col = "black")
dev.off()

# Record R session info
writeLines(capture.output(sessionInfo()), "results/session_info.txt")

cat("Completed country analysis for", country_name, "(", country_code, "). Check data/, figures/, results/.\n")
