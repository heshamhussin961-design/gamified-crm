import json
import os
import re
from datetime import datetime, timedelta
from typing import Any

from dotenv import load_dotenv

# Try to import Supabase, handle error if not installed
try:
    from supabase import Client, create_client
except ImportError:
    print("Error: supabase library not found. Run: pip install supabase")
    exit(1)

# Load environment variables explicitly
env_path = os.path.join(os.getcwd(), '.env')
load_dotenv(dotenv_path=env_path)

# ==================== Configuration ====================
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_KEY') # Needs Service Key for bulk operations

class LeadDistributor:
    def __init__(self):
        if not SUPABASE_URL or not SUPABASE_KEY:
            raise ValueError("SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in .env")
        self.supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

    def clean_phone(self, phone: str) -> str:
        """Removes all non-numeric characters from the phone number."""
        if not phone:
            return ""
        return re.sub(r'\D', '', str(phone))

    def get_active_agents(self) -> list[str]:
        """Fetches IDs of all active sales agents from the database."""
        response = self.supabase.table('employees') \
            .select('id') \
            .eq('role', 'sales_agent') \
            .eq('is_active', True) \
            .execute()
        return [emp['id'] for emp in response.data]

    def distribute_leads(self, leads_data: list[dict[str, Any]], batch_size: int = 100):
        """
        Distributes leads to active agents using a Round Robin algorithm.
        Optimized with batching to handle thousands of records efficiently.
        """
        agents = self.get_active_agents()
        if not agents:
            print("Error: No active sales agents found in the system.")
            return

        total_leads = len(leads_data)
        num_agents = len(agents)

        print(f"Starting distribution of {total_leads} leads to {num_agents} agents...")

        processed_leads = []

        for i, lead in enumerate(leads_data):
            # 1. Clean data
            phone_clean = self.clean_phone(lead.get('phone', ''))
            if not phone_clean:
                continue

            # 2. Assign agent (Round Robin)
            agent_id = agents[i % num_agents]

            lead_entry = {
                "phone": lead.get('phone'),
                "phone_clean": phone_clean,
                "name": lead.get('name'),
                "country_code": lead.get('country_code'),
                "source": lead.get('source', 'bulk_import'),
                "imported_from": lead.get('imported_from', 'leads.json'),
                "assigned_to": agent_id,
                "status": "new",
                "created_at": datetime.utcnow().isoformat()
            }
            processed_leads.append(lead_entry)

        # 3. Batch Upload Leads to Supabase
        print(f"Uploading {len(processed_leads)} leads in batches of {batch_size}...")
        for i in range(0, len(processed_leads), batch_size):
            batch = processed_leads[i:i + batch_size]
            try:
                result = self.supabase.table('leads').insert(batch).execute()

                # 4. Generate Quests for assigned leads
                if result.data:
                    batch_quests = []
                    for inserted_lead in result.data:
                        batch_quests.append({
                            "employee_id": inserted_lead['assigned_to'],
                            "lead_id": inserted_lead['id'],
                            "title": "First Contact: " + (inserted_lead['name'] or inserted_lead['phone']),
                            "description": "Reach out to this new lead via WhatsApp or Phone.",
                            "status": "pending",
                            "xp_reward": 20,
                            "coin_reward": 2,
                            "due_at": (datetime.utcnow() + timedelta(hours=24)).isoformat()
                        })
                    self.supabase.table('quests').insert(batch_quests).execute()

                print(f"   Processed batch {i//batch_size + 1}/{(len(processed_leads)//batch_size)+1}")
            except Exception as e:
                print(f"   Error in batch {i//batch_size + 1}: {str(e)}")

        print("\nLead distribution completed successfully!")

def main():
    # Load leads from the provided local json file
    json_path = 'عمرو_leads.json'

    if not os.path.exists(json_path):
        print(f"❌ Error: {json_path} not found.")
        return

    with open(json_path, encoding='utf-8') as f:
        leads_data = json.load(f)

    distributor = LeadDistributor()
    distributor.distribute_leads(leads_data)

if __name__ == "__main__":
    main()
