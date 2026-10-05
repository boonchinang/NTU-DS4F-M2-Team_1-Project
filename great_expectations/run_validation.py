import os
import sys
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

def main():
    print("Starting Great Expectations / SQLAlchemy Quality Gate...")
    
    # Load environment variables from .env file
    load_dotenv()
    
    # Configure Service Account Key
    key_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS") or "../.gcp/sa_key.json"
    if os.path.exists(key_path):
        os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = os.path.abspath(key_path)
        print(f"🔑 Authenticated via Service Account Key: {os.path.abspath(key_path)}")
    else:
        print(f"⚠️ Service account keyfile not found at {key_path}, using default credentials environment.")

    project_id = os.getenv("GCP_PROJECT_ID", "<YOUR_GCP_PROJECT_ID>")
    dataset_id = "london_bicycles_marts"
    location = "EU"
    
    connection_url = f"bigquery://{project_id}/{dataset_id}?location={location}"
    print(f"📡 Connecting via SQLAlchemy: {connection_url}")
    
    try:
        engine = create_engine(connection_url)
        query = text(f"""
            SELECT 
                (SELECT COUNT(*) FROM ) as total_rentals,
                (SELECT COUNT(*) FROM ) as total_stations,
                (SELECT COUNT(*) FROM  
                 WHERE start_station_key NOT IN (SELECT station_key FROM )) as orphan_rentals,
                (SELECT AVG(duration_seconds) FROM ) as avg_duration,
                (SELECT COUNT(*) FROM  WHERE bike_capacity < 0) as invalid_docks
        """)
        
        with engine.connect() as conn:
            result = conn.execute(query)
            row = result.mappings().first()
            res = dict(row)
            
        print(f"📊 Quality Metrics: {res}")
        
        errors = []
        if res['total_rentals'] == 0:
            errors.append("fact_rentals table is empty!")
        if res['total_stations'] == 0:
            errors.append("dim_stations table is empty!")
        if res['orphan_rentals'] > 0:
            errors.append(f"Found {res['orphan_rentals']} orphan rentals referencing missing stations!")
        if res['invalid_docks'] > 0:
            errors.append(f"Found {res['invalid_docks']} stations with negative dock counts!")
        if res['avg_duration'] is None or res['avg_duration'] < 60 or res['avg_duration'] > 86400:
            errors.append(f"Average duration anomaly detected: {res['avg_duration']}s")
            
        if not errors:
            print("✅ ALL GREAT EXPECTATIONS SQLALCHEMY QUALITY CHECKS PASSED 100%")
            sys.exit(0)
        else:
            print(f"❌ GREAT EXPECTATIONS VALIDATION FAILED with {len(errors)} errors:")
            for err in errors:
                print(f"   - {err}")
            sys.exit(1)
            
    except Exception as e:
        print(f"❌ SQLAlchemy Execution Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
