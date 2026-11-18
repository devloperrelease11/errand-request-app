from app.database import Base, SessionLocal, engine
from app.models import Errand, User, utcnow
from app.security import hash_password
from datetime import timedelta
from uuid import NAMESPACE_DNS, uuid5

DEMO_PASSWORD = "Demo1234!"


def demo_id(label: str) -> str:
    return str(uuid5(NAMESPACE_DNS, f"erand-demo-{label}"))


def main() -> None:
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        accounts = [
            ("requester", "Asha Requester", "requester@example.com"),
            ("runner", "Ravi Runner", "runner@example.com"),
            ("runner2", "Meera Runner", "runner2@example.com"),
            ("requester2", "Noah Requester", "requester2@example.com"),
        ]
        for label, name, email in accounts:
            if db.get(User, demo_id(label)) is None:
                db.add(
                    User(
                        id=demo_id(label),
                        name=name,
                        email=email,
                        password_hash=hash_password(DEMO_PASSWORD),
                        role="runner" if "runner" in label else "requester",
                        created_at=utcnow() - timedelta(days=7),
                    )
                )
        db.commit()

        if db.query(Errand).count() == 0:
            now = utcnow()
            rows = [
                dict(
                    label="groceries",
                    title="Pick up groceries",
                    description="Collect the pre-paid order from Green Market and bring it to my flat.",
                    pickup="Green Market, 12 Hill Street",
                    dropoff="42 Lake Road, Apt 3B",
                    requester="requester",
                    runner=None,
                    status="Open",
                    created_hours=4,
                ),
                dict(
                    label="documents",
                    title="Drop off signed documents",
                    description="Collect the envelope from the front desk and deliver it to the courier office.",
                    pickup="Front desk, West Tower",
                    dropoff="Courier Office, 8 Canal Lane",
                    requester="requester",
                    runner=None,
                    status="Open",
                    created_hours=3,
                ),
                dict(
                    label="library",
                    title="Return library books",
                    description="Three books are bagged by the entrance; return them to the city library.",
                    pickup="42 Lake Road, Apt 3B",
                    dropoff="City Library, Main Hall",
                    requester="requester",
                    runner="runner",
                    status="Accepted",
                    created_hours=2,
                    accepted_hours=1,
                ),
                dict(
                    label="drycleaning",
                    title="Collect dry cleaning",
                    description="Pick up the order using ticket number 4821.",
                    pickup="Spotless Cleaners, Market Road",
                    dropoff="42 Lake Road, Apt 3B",
                    requester="requester",
                    runner="runner",
                    status="Completed",
                    created_hours=48,
                    accepted_hours=47,
                    completed_hours=46,
                ),
                dict(
                    label="flowers",
                    title="Buy flowers",
                    description="No longer needed, order was cancelled.",
                    pickup="Flower Stall, North Square",
                    dropoff="42 Lake Road, Apt 3B",
                    requester="requester",
                    runner=None,
                    status="Cancelled",
                    created_hours=24,
                ),
                dict(
                    label="pharmacy",
                    title="Collect pharmacy prescription",
                    description="Pick up the prepared package and bring it to the reception desk.",
                    pickup="Central Pharmacy, 5 Oak Avenue",
                    dropoff="17 Pine Close, Reception",
                    requester="requester2",
                    runner=None,
                    status="Open",
                    created_hours=1,
                ),
            ]
            for row in rows:
                db.add(
                    Errand(
                        id=demo_id(f"errand-{row['label']}"),
                        requester_id=demo_id(row["requester"]),
                        runner_id=demo_id(row["runner"]) if row["runner"] else None,
                        title=row["title"],
                        description=row["description"],
                        pickup_address=row["pickup"],
                        dropoff_address=row["dropoff"],
                        status=row["status"],
                        created_at=now - timedelta(hours=row["created_hours"]),
                        updated_at=now - timedelta(hours=row.get("completed_hours", row.get("accepted_hours", row["created_hours"]))),
                        accepted_at=now - timedelta(hours=row["accepted_hours"]) if row.get("accepted_hours") else None,
                        completed_at=now - timedelta(hours=row["completed_hours"]) if row.get("completed_hours") else None,
                    )
                )
            db.commit()
            print("Seed errands created.")
        else:
            print("Errands already present; skipped sample errands.")

        print(f"Demo accounts (password: {DEMO_PASSWORD}):")
        for _, _, email in accounts:
            print(f"  {email}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
