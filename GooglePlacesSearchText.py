import csv, sys, urllib.request, os, json
import requests
import json
import pathlib
import pandas as pd

YOUR_API_KEY = "<YOUR API KEY>"
INITIALIZED_CSV = False
KEYWORD_IN = "restaurant"

#FIELD_MASK = 'nextPageToken,places.displayName.text,places.nationalPhoneNumber,places.internationalPhoneNumber,places.formattedAddress,places.websiteUri,places.googleMapsUri'
FIELD_MASK = 'nextPageToken,places.displayName.text,places.nationalPhoneNumber,places.internationalPhoneNumber,places.formattedAddress,places.websiteUri,places.googleMapsUri,places.id'
COLUMN_NAMES = ['displayName.text','nationalPhoneNumber','internationalPhoneNumber','formattedAddress','websiteUri','googleMapsUri','id']
# GOOGLE API QUERY
#QUERY_URL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?name={KEYWORD}&location={LOCATION}&radius={RADIUS}&key={KEY}"


def getPlaceInfo(keyword, city, town, next_page_token):
    global INITIALIZED_CSV
    #outputFile = pathlib.Path(OUTPUT_FOLDER, f'{city}_{town}.csv')
    outputFile = pathlib.Path(OUTPUT_FOLDER, f'PlacesData.csv')

    while True:
        flat_data, next_page_token = getNextPage(keyword, city, town, next_page_token)
        if flat_data is None:
            break

        if not INITIALIZED_CSV:
            flat_data.to_csv(outputFile, index=False, encoding="utf-8-sig", sep=";", mode='w')
        else :
            flat_data.to_csv(outputFile, index=False, encoding="utf-8-sig", sep=";", mode='a', header=False)

        INITIALIZED_CSV = True

        if len(next_page_token) == 0:
            break


def getNextPage(keyword, city, town, next_page_token):
    headers = {'Content-Type': 'application/json',
               'X-Goog-Api-Key': YOUR_API_KEY,
               'X-Goog-FieldMask': FIELD_MASK}

    QUERY_URL = "https://places.googleapis.com/v1/places:searchText?textQuery={KEYWORD} in {LOCATION}&page_token={PAGE_TOKEN}"
    location = f'{town.lower()}-{city.lower()}'
    query = QUERY_URL.format(KEYWORD=keyword, LOCATION=location, PAGE_TOKEN=next_page_token)
    response = requests.post(query, headers=headers)
    if (response.status_code == 200):
        json_result = json.loads(response.text)

        places = None
        if not (json_result.get('places') is None):
            places = json_result['places']

        if places is not None:
            next_page_token = ''
            if not (json_result.get('nextPageToken') is None):
                 next_page_token = json_result['nextPageToken']

            flat_data = pd.json_normalize(places, meta=COLUMN_NAMES)
            index = 0
            for col in COLUMN_NAMES:
                if col not in flat_data.columns:
                    flat_data.insert(index, col, '')
                index += 1

            flat_data.insert(0, 'city', city)
            flat_data.insert(1, 'town', town)
            flat_data = flat_data.loc[:,['city', 'town'] + COLUMN_NAMES]

            return flat_data, next_page_token

        return None, None

def processPlaces(keyword):
    df = pd.read_csv("tr.csv", sep='[;]', encoding='utf-8-sig', engine='python', header='infer')
    for row in df.itertuples():
        getPlaceInfo(keyword, row.city, row.town, next_page_token='')



if __name__=="__main__":
    processPlaces(KEYWORD_IN)
    #crawlLocationFrom(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]))
    
          

    







