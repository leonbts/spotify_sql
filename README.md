# Electronic Music Popularity Analysis

This project focuses on analyzing a large dataset of electronic music tracks (approximately 5.7 million) obtained from kaggle.com. The primary goal is to identify factors influencing the popularity of electronic music.

The following steps have been completed as part of this project:

## Project Steps

* **Data Exploration and Preparation:** Loading and cleaning data from multiple tables, unifying data types.
* **Data Organization:** Creating a MySQL database structure using foreign keys to link tables.
* **Exploratory Data Analysis (EDA):**
    * Analyzing track duration over the years.
    * Analyzing individual releases and their audio features.
    * Identifying top artists based on the number of tracks.
    * Investigating the correlation of danceability, valence, and loudness with popularity.
    * Analyzing how the trend of artists creating collaborative tracks and track duration has changed over the last 30 years.
* **Visualization:** Creating informative graphs using Python (matplotlib, seaborn) to represent the analysis results (e.g., number of tracks and average number of artists per year).

## Data Source

The dataset used for this project is available at:

[https://www.kaggle.com/datasets/mcfurland/10-m-beatport-tracks-spotify-audio-features/data](https://www.kaggle.com/datasets/mcfurland/10-m-beatport-tracks-spotify-audio-features/data)

## Project Files

* **SQL Queries for Data Preparation:** `main.sql`
* **Graphs and Analysis (Python Notebook):** `main.ipynb`
* **Presentation with Results Description:** `Spotify.pptx`