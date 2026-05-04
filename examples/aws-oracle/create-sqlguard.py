#!/usr/bin/env python3
import oracledb
import sys

# Connection details
host = "nexus-oracle-rds.c1wbwkkrn7x2.us-east-2.rds.amazonaws.com"
port = 1521
service = "ORCL"
admin_user = "admin"
admin_pass = "OracleAdmin123!"

print("Connecting to Oracle...")
try:
    conn = oracledb.connect(user=admin_user, password=admin_pass, 
                            dsn=f"{host}:{port}/{service}")
    cursor = conn.cursor()
    
    print("Creating sqlguard user...")
    cursor.execute("CREATE USER sqlguard IDENTIFIED BY \"SqlGuard456!\"")
    cursor.execute("GRANT CREATE SESSION TO sqlguard")
    cursor.execute("GRANT CONNECT TO sqlguard")
    cursor.execute("GRANT SELECT ANY DICTIONARY TO sqlguard")
    cursor.execute("GRANT SELECT_CATALOG_ROLE TO sqlguard")
    
    conn.commit()
    print("✅ SUCCESS: sqlguard user created!")
    print("\nTest in Guardium with:")
    print("  Username: sqlguard")
    print("  Password: SqlGuard456!")
    
except Exception as e:
    print(f"❌ ERROR: {e}")
    sys.exit(1)
finally:
    if 'conn' in locals():
        conn.close()

# Made with Bob
