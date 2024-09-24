package main

import (
	"encoding/csv"
	"flag"
	"fmt"
	"io"
	"log"
	"math"
	"os"
	"strconv"
)

type Record struct {
	Date  string
	Point Point
}

type Point struct {
	Latitude  float64
	Longitude float64
}

func main() {
	if err := run(); err != nil {
		log.New(os.Stderr, "error: ", 0).Fatal(err)
	}
}

func run() error {
	var baseLatitude float64
	var baseLongitude float64

	flag.Float64Var(&baseLatitude, "latitude", 0.0, "基準点の緯度")
	flag.Float64Var(&baseLongitude, "longitude", 0.0, "基準点の経度")

	flag.Parse()

	if len(flag.Args()) < 1 {
		return nil
	}

	file, err := os.Open(flag.Args()[0])

	if err != nil {
		return err
	}

	defer file.Close()

	records := []*Record{}
	reader := csv.NewReader(file)

	for {
		columns, err := reader.Read()

		if err == io.EOF {
			break
		}
		if err != nil {
			return nil
		}
		if len(columns) != 3 {
			return fmt.Errorf("invalid columns: %+v", columns)
		}
		if columns[0] == "Date" {
			continue
		}

		record, err := parse(columns)

		if err != nil {
			return err
		}

		records = append(records, record)
	}
	if len(records) < 1 {
		return nil
	}

	base := Point{
		Latitude:  baseLatitude,
		Longitude: baseLongitude,
	}

	fmt.Println("Date,Distance")

	for i := range records {
		distance := haversine(base, records[i].Point)

		fmt.Printf("%s,%.1f\n", records[i].Date, distance)
	}

	return nil
}

func parse(columns []string) (*Record, error) {
	latitude, err := strconv.ParseFloat(columns[1], 64)

	if err != nil {
		return nil, err
	}

	longitude, err := strconv.ParseFloat(columns[2], 64)

	if err != nil {
		return nil, err
	}

	record := Record{
		Date: columns[0],
		Point: Point{
			Latitude:  latitude,
			Longitude: longitude,
		},
	}

	return &record, nil
}

func haversine(p1, p2 Point) float64 {
	// Earth radius in kilometers
	const R = 6371.0

	lat1 := p1.Latitude * math.Pi / 180.0
	lon1 := p1.Longitude * math.Pi / 180.0
	lat2 := p2.Latitude * math.Pi / 180.0
	lon2 := p2.Longitude * math.Pi / 180.0

	dLat := lat2 - lat1
	dLon := lon2 - lon1

	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1)*math.Cos(lat2)*math.Sin(dLon/2)*math.Sin(dLon/2)

	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))

	// Distance in meters
	distance := R * c * 1000.0

	return distance
}
