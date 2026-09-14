"""
seed_db.py — Populates the database with realistic demo data for SIH presentation.

Creates:
  - 5 paramilitary units
  - 2 dashboard users (Commander + Welfare Officer, matching dashboard demo credentials)
  - ~50 personnel with activation codes
  - 30 days of wellness check-in history per personnel
  - HR metrics with simulated HRV data
  - AI assessments with realistic narratives for ~20 personnel
  - Mix of risk levels: Routine / Monitor / Intervention_Recommended

Run:
    cd backend
    pip install -r requirements.txt
    python scripts/seed_db.py

Set DATABASE_URL in .env before running.
"""
import asyncio
import random
import uuid
from datetime import datetime, date, timedelta, timezone
from typing import Optional
import math

# ── Bootstrap path ────────────────────────────────────────────────────────────
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv
load_dotenv()

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy import text

from app.config import get_settings
from app.models.user import User, Unit, ActivationCode, UserRole
from app.models.checkin import WellnessCheckin, RiskLevel
from app.models.hr_metrics import HRMetrics
from app.models.assessment import AIAssessment, AssessmentStatus, SupportRequest
from app.utils.security import hash_password
from app.utils.encryption import encrypt_text

settings = get_settings()
random.seed(42)

# ── Constants ─────────────────────────────────────────────────────────────────

UNITS = [
    "102 Bn CRPF",
    "78 Bn BSF",
    "45 Bn ITBP",
    "33 Bn SSB",
    "12 Bn CISF",
]

# Indian paramilitary personnel names (realistic)
NAMES = [
    ("Rajesh Kumar", "Constable"), ("Priya Sharma", "Sub-Inspector"),
    ("Amit Singh", "Constable"), ("Sunita Devi", "Head Constable"),
    ("Vikram Yadav", "Constable"), ("Meena Gupta", "Sub-Inspector"),
    ("Arjun Patel", "Head Constable"), ("Kavita Joshi", "Constable"),
    ("Suresh Tiwari", "Inspector"), ("Anita Rao", "Constable"),
    ("Mohan Das", "Head Constable"), ("Deepika Nair", "Constable"),
    ("Santosh Kumar", "Sub-Inspector"), ("Rekha Verma", "Constable"),
    ("Anil Sharma", "Inspector"), ("Pooja Singh", "Head Constable"),
    ("Ramesh Gupta", "Constable"), ("Sushma Yadav", "Sub-Inspector"),
    ("Dinesh Patel", "Constable"), ("Lata Joshi", "Constable"),
    ("Manoj Kumar", "Head Constable"), ("Anjali Tiwari", "Constable"),
    ("Sunil Das", "Sub-Inspector"), ("Neeta Rao", "Constable"),
    ("Rakesh Verma", "Constable"), ("Savita Sharma", "Inspector"),
    ("Dilip Singh", "Constable"), ("Usha Gupta", "Head Constable"),
    ("Naresh Yadav", "Constable"), ("Geeta Patel", "Sub-Inspector"),
    ("Hemant Joshi", "Constable"), ("Mamta Kumar", "Constable"),
    ("Pankaj Das", "Head Constable"), ("Kiran Rao", "Sub-Inspector"),
    ("Vikas Verma", "Constable"), ("Shanti Singh", "Constable"),
    ("Rajan Sharma", "Inspector"), ("Asha Gupta", "Constable"),
    ("Kuldeep Yadav", "Head Constable"), ("Nirmala Patel", "Constable"),
    ("Devendra Joshi", "Constable"), ("Sudha Tiwari", "Sub-Inspector"),
    ("Brijesh Das", "Constable"), ("Kamla Rao", "Constable"),
    ("Harish Verma", "Head Constable"), ("Manju Sharma", "Constable"),
    ("Umesh Singh", "Inspector"), ("Pushpa Gupta", "Constable"),
    ("Narendra Yadav", "Constable"), ("Vimla Patel", "Sub-Inspector"),
]

# Dashboard officer accounts (match the demo credentials in the dashboard code)
DASHBOARD_USERS = [
    {
        "username": "cmd_sharma",
        "full_name": "Col. Vikram Sharma",
        "service_id": "CRPF-10201",
        "role": UserRole.COMMANDER,
        "pin": "demo123",  # dashboard password
        "unit_idx": 0,
    },
    {
        "username": "wo_meera",
        "full_name": "Welfare Officer Meera Singh",
        "service_id": "CRPF-20301",
        "role": UserRole.WELFARE_OFFICER,
        "pin": "demo123",
        "unit_idx": 0,
    },
]

# Contributing factors templates for each risk level
FACTORS = {
    RiskLevel.INTERVENTION: [
        "{days} days without leave, duty hours exceeding {hours}h/wk, HRV deviation +{hrv:.1f}%",
        "Persistent sleep deficit (avg {sleep:.1f}/5), mood declining over {days_d} days, leave overdue by {leave_overdue} days",
        "HRV deviation +{hrv:.1f}%, {days} consecutive days with overall score ≤ 2, high fatigue markers",
        "Operational stress: {months}mo continuous deployment, duty hours {hours}h/wk, focus score ≤ 2 for {days_d} days",
    ],
    RiskLevel.MONITOR: [
        "Sleep scores declining (avg {sleep:.1f}/5), moderate HRV deviation ({hrv:.1f}%), leave deficit {days} days",
        "Elevated duty hours ({hours}h/wk), mood below average for {days_d} days, monitoring recommended",
        "HRV deviation {hrv:.1f}%, physical score trending down over {days_d} days, borderline leave deficit",
        "Focus impairment noted for {days_d} days, sleep recovery {sleep:.1f}/5, watchlist recommended",
    ],
    RiskLevel.ROUTINE: [
        "No significant stress indicators. Wellness scores within normal range.",
        "Routine monitoring. Scores stable, leave schedule on track.",
        "Personnel functioning well. Minor fatigue noted, within acceptable range.",
        "No welfare action required. Check-in adherence good.",
    ],
}

INTERVENTIONS = {
    RiskLevel.INTERVENTION: [
        "Immediate 14-day leave approval and duty rebalancing recommended",
        "Welfare officer consultation within 48 hours, duty hour reduction to <48h/wk",
        "Priority leave scheduling, peer counseling referral, medical wellness screening",
        "Urgent: duty stand-down, psychological support referral, leave approval",
    ],
    RiskLevel.MONITOR: [
        "Schedule welfare check-in within 7 days, monitor for escalation",
        "Duty hour review, voluntary counseling offered, follow-up in 14 days",
        "Leave scheduling review, peer support session recommended",
        "Close monitoring for 2 weeks, consider reduced operational tempo",
    ],
    RiskLevel.ROUTINE: [
        "Continue routine monitoring. No action required at this time.",
        "Standard check-in schedule maintained.",
        "No intervention required. Acknowledge routine status.",
        "Personnel in good standing. Routine review in 30 days.",
    ],
}

AI_NARRATIVES = {
    RiskLevel.INTERVENTION: [
        "Biometric analysis reveals significant autonomic dysregulation (HRV deviation >{hrv:.0f}%) correlating with self-reported psychological strain. Combined operational stressors — {months} months continuous deployment and {hours}h/wk duty load — exceed sustainable thresholds. Immediate welfare intervention is clinically warranted to prevent burnout escalation.",
        "Multi-dimensional stress convergence detected: physiological markers (HRV, sleep recovery) combined with sustained psychological load suggest high burnout risk. Leave deficit of {days} days is a primary driver. Immediate command action recommended to restore operational readiness.",
    ],
    RiskLevel.MONITOR: [
        "Early stress markers identified across biometric and self-report channels. HRV deviation ({hrv:.1f}%) and declining sleep recovery scores suggest emerging autonomic strain. Current trajectory warrants close monitoring and proactive welfare engagement to prevent escalation to intervention-required status.",
        "Moderate stress accumulation observed. Duty hours ({hours}h/wk) approaching critical threshold. Self-reported mood and focus scores showing downward trend over {days_d} days. Recommend scheduled welfare check-in and leave planning discussion.",
    ],
    RiskLevel.ROUTINE: [
        "Personnel demonstrating healthy stress regulation. Wellness indicators — mood, sleep, physical, and focus scores — are within expected operational norms. No biometric anomalies detected. Continue standard monitoring protocol.",
        "Stable psychological and physiological profile. HRV within normal baseline. Self-reported wellness scores consistent and positive. Personnel exhibiting good resilience markers. No welfare action required.",
    ],
}


# ── Utility helpers ───────────────────────────────────────────────────────────

def make_service_id(unit_name: str, idx: int) -> str:
    prefix = "".join(w[0] for w in unit_name.split() if w[0].isalpha())[:4].upper()
    return f"{prefix}-{10000 + idx:05d}"


def make_activation_code(idx: int) -> str:
    chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    random.seed(idx * 7 + 13)
    part1 = "".join(random.choice(chars) for _ in range(4))
    part2 = "".join(random.choice(chars) for _ in range(4))
    random.seed(42)  # reset
    return f"{part1}-{part2}"


def simulate_hrv(base_risk: RiskLevel) -> float:
    """Simulate HRV baseline deviation (%) based on risk tier."""
    if base_risk == RiskLevel.INTERVENTION:
        return round(random.uniform(18.0, 35.0), 1)
    elif base_risk == RiskLevel.MONITOR:
        return round(random.uniform(8.0, 20.0), 1)
    else:
        return round(random.uniform(0.5, 10.0), 1)


def simulate_duty_hours(base_risk: RiskLevel) -> float:
    if base_risk == RiskLevel.INTERVENTION:
        return round(random.uniform(54.0, 68.0), 1)
    elif base_risk == RiskLevel.MONITOR:
        return round(random.uniform(48.0, 58.0), 1)
    else:
        return round(random.uniform(38.0, 50.0), 1)


def simulate_leave_days(base_risk: RiskLevel) -> int:
    if base_risk == RiskLevel.INTERVENTION:
        return random.randint(90, 180)
    elif base_risk == RiskLevel.MONITOR:
        return random.randint(40, 95)
    else:
        return random.randint(5, 45)


def simulate_deployment_months(base_risk: RiskLevel) -> int:
    if base_risk == RiskLevel.INTERVENTION:
        return random.randint(15, 30)
    elif base_risk == RiskLevel.MONITOR:
        return random.randint(8, 18)
    else:
        return random.randint(2, 12)


def compute_risk(checkins: list[dict], hr: dict) -> RiskLevel:
    """Rule-based risk classification (no ML needed for seed data)."""
    if not checkins:
        return RiskLevel.ROUTINE

    avg_overall = sum(c["overall_score"] for c in checkins[-14:]) / min(len(checkins), 14)
    avg_sleep = sum(c["sleep_score"] for c in checkins[-14:]) / min(len(checkins), 14)
    consecutive_low = sum(1 for c in checkins[-5:] if c["overall_score"] <= 2)
    hrv = hr["hrv_baseline_deviation"]
    leave = hr["days_since_last_leave"]
    duty = hr["avg_weekly_duty_hours"]

    # Critical indicators
    if (hrv > 25 and leave > 120) or consecutive_low >= 3 or avg_overall < 2.0:
        return RiskLevel.INTERVENTION
    if (hrv > 15 and leave > 80) or consecutive_low >= 2 or avg_overall < 3.0 or duty > 58:
        return RiskLevel.MONITOR
    return RiskLevel.ROUTINE


def make_checkin_scores(day_offset: int, base_risk: RiskLevel, seed_offset: int) -> dict:
    """Generate realistic daily check-in scores with trends."""
    random.seed(seed_offset + day_offset * 17)

    if base_risk == RiskLevel.INTERVENTION:
        # Declining trend toward the end
        progress = day_offset / 30  # 0 = old, 1 = recent
        base = max(1.0, 3.5 - progress * 2.0)
        spread = 1.2
    elif base_risk == RiskLevel.MONITOR:
        base = random.uniform(2.5, 3.5)
        spread = 1.0
    else:
        base = random.uniform(3.2, 4.8)
        spread = 0.8

    def score():
        s = round(base + random.uniform(-spread, spread))
        return max(1, min(5, s))

    avg = (score() + score() + score() + score()) / 4
    overall, sleep, physical, focus = score(), score(), score(), score()
    random.seed(42)
    return {
        "overall_score": overall,
        "sleep_score": sleep,
        "physical_score": physical,
        "focus_score": focus,
        "average_score": round((overall + sleep + physical + focus) / 4, 2),
    }


def compute_resilience(mood: float, sleep: float, fatigue: float) -> int:
    """Dashboard formula: clamp(15, 98, (mood×5) + (sleep×3) − (fatigue×2) + 20)."""
    raw = (mood * 5) + (sleep * 3) - (fatigue * 2) + 20
    return max(15, min(98, round(raw)))


def pick(options: dict, risk: RiskLevel) -> str:
    return random.choice(options[risk])


def format_factor(template: str, **kwargs) -> str:
    try:
        return template.format(**kwargs)
    except KeyError:
        return template


# ── Main seeding logic ────────────────────────────────────────────────────────

async def seed():
    engine = create_async_engine(settings.DATABASE_URL, echo=False, connect_args={"statement_cache_size": 0})
    AsyncSession_ = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with AsyncSession_() as session:
        print("🌱 Starting seed...")

        # ── 1. Units ──────────────────────────────────────────────────────────
        unit_objs: dict[str, Unit] = {}
        for unit_name in UNITS:
            unit = Unit(id=uuid.uuid4(), name=unit_name)
            session.add(unit)
            unit_objs[unit_name] = unit
        await session.flush()
        print(f"  ✅ Created {len(UNITS)} units")

        # ── 2. Dashboard officers ─────────────────────────────────────────────
        for du in DASHBOARD_USERS:
            user = User(
                id=uuid.uuid4(),
                service_id=du["service_id"],
                username=du["username"],
                full_name=du["full_name"],
                unit_id=unit_objs[UNITS[du["unit_idx"]]].id,
                pin_hash=hash_password(du["pin"]),
                role=du["role"],
                is_active=True,
                consent_given=True,
                consent_given_at=datetime.now(timezone.utc) - timedelta(days=60),
            )
            session.add(user)
            # HR metrics for officers too
            hr = HRMetrics(
                id=uuid.uuid4(),
                user_id=user.id,
                avg_weekly_duty_hours=45.0,
                days_since_last_leave=10,
                deployment_history_months=6,
                hrv_baseline_deviation=3.2,
                avg_mood_score=7.5,
                avg_sleep_recovery=7.0,
                avg_fatigue_level=3.0,
                last_updated=datetime.now(timezone.utc),
            )
            session.add(hr)
        await session.flush()
        print(f"  ✅ Created {len(DASHBOARD_USERS)} dashboard users (cmd_sharma, wo_meera)")

        # ── 3. Personnel + activation codes + HR metrics + checkins ───────────
        # Distribute risk tiers: 60% Routine, 25% Monitor, 15% Intervention
        risk_distribution = (
            [RiskLevel.ROUTINE] * 30 +
            [RiskLevel.MONITOR] * 12 +
            [RiskLevel.INTERVENTION] * 8
        )
        random.shuffle(risk_distribution)

        today = date.today()
        all_personnel: list[User] = []

        for idx, (full_name, rank) in enumerate(NAMES):
            unit_name = UNITS[idx % len(UNITS)]
            unit = unit_objs[unit_name]
            base_risk = risk_distribution[idx]

            service_id = make_service_id(unit_name, idx + 1)
            username = f"{rank.lower().replace('-', '_').replace(' ', '_')}_{idx + 1}"
            code = make_activation_code(idx)

            # Activation code
            activation = ActivationCode(
                id=uuid.uuid4(),
                code=code,
                unit_id=unit.id,
                is_used=True,
                used_at=datetime.now(timezone.utc) - timedelta(days=random.randint(30, 90)),
            )
            session.add(activation)

            # User
            user = User(
                id=uuid.uuid4(),
                service_id=service_id,
                username=username,
                full_name=f"{rank} {full_name}",
                unit_id=unit.id,
                pin_hash=hash_password("123456"),  # default PIN for demo
                role=UserRole.PERSONNEL,
                is_active=True,
                consent_given=True,
                consent_given_at=datetime.now(timezone.utc) - timedelta(days=random.randint(20, 80)),
            )
            session.add(user)
            all_personnel.append(user)

            # HR Metrics (with simulated HRV)
            hrv = simulate_hrv(base_risk)
            duty = simulate_duty_hours(base_risk)
            leave_days = simulate_leave_days(base_risk)
            deployment = simulate_deployment_months(base_risk)

            # Map 1-5 dimension scores to 1-10 scale for dashboard display
            recent_scores = [make_checkin_scores(i, base_risk, idx * 100) for i in range(25, 30)]
            avg_mood = round(sum(s["overall_score"] for s in recent_scores) / len(recent_scores) * 2, 1)
            avg_sleep = round(sum(s["sleep_score"] for s in recent_scores) / len(recent_scores) * 2, 1)
            avg_fatigue = round(10 - sum(s["physical_score"] for s in recent_scores) / len(recent_scores) * 2, 1)

            hr = HRMetrics(
                id=uuid.uuid4(),
                user_id=user.id,
                avg_weekly_duty_hours=duty,
                days_since_last_leave=leave_days,
                deployment_history_months=deployment,
                hrv_baseline_deviation=hrv,
                avg_mood_score=avg_mood,
                avg_sleep_recovery=avg_sleep,
                avg_fatigue_level=avg_fatigue,
                last_updated=datetime.now(timezone.utc),
            )
            session.add(hr)
            await session.flush()

            # 30 days of check-in history
            checkin_data_list = []
            for day_back in range(29, -1, -1):
                # Skip ~10% of days (missed check-ins)
                if random.random() < 0.10:
                    continue
                checkin_date = today - timedelta(days=day_back)
                scores = make_checkin_scores(29 - day_back, base_risk, idx * 100 + day_back)
                note = ""
                if random.random() < 0.3:
                    notes_pool = [
                        "Long patrol yesterday, feeling tired.",
                        "Slept better last night.",
                        "High stress on duty today.",
                        "Good PT session this morning.",
                        "Missing family, morale is low.",
                        "Feeling focused and ready.",
                        "Very hot weather affecting energy.",
                        "Team bonding session helped.",
                        "Worried about home situation.",
                        "Good communication with unit today.",
                    ]
                    note = random.choice(notes_pool)

                checkin = WellnessCheckin(
                    id=uuid.uuid4(),
                    user_id=user.id,
                    checkin_date=checkin_date,
                    overall_score=scores["overall_score"],
                    sleep_score=scores["sleep_score"],
                    physical_score=scores["physical_score"],
                    focus_score=scores["focus_score"],
                    average_score=scores["average_score"],
                    note_encrypted=encrypt_text(note, str(user.id)) if note else None,
                    risk_level=compute_risk(
                        [make_checkin_scores(i, base_risk, idx * 100 + i) for i in range(max(0, 29 - day_back - 14), 29 - day_back + 1)],
                        {"hrv_baseline_deviation": hrv, "days_since_last_leave": leave_days, "avg_weekly_duty_hours": duty}
                    ),
                    created_at=datetime.combine(checkin_date, datetime.min.time()).replace(tzinfo=timezone.utc),
                )
                session.add(checkin)
                checkin_data_list.append(scores)

        await session.flush()
        print(f"  ✅ Created {len(NAMES)} personnel with 30d check-in history")

        # ── 4. AI Assessments ─────────────────────────────────────────────────
        # Create assessments for ~20 personnel with non-routine risk
        assessment_targets = [
            (u, r) for u, r in zip(all_personnel, risk_distribution)
            if r in (RiskLevel.INTERVENTION, RiskLevel.MONITOR)
        ]
        random.shuffle(assessment_targets)

        # Load HR metrics we just created
        await session.flush()
        from sqlalchemy import select
        hr_by_user: dict[uuid.UUID, HRMetrics] = {}
        hrs = await session.execute(select(HRMetrics))
        for hr_row in hrs.scalars():
            hr_by_user[hr_row.user_id] = hr_row

        # Welfare officers handle assessments
        wo_user = None
        result = await session.execute(
            select(User).where(User.username == "wo_meera")
        )
        wo_user = result.scalar_one_or_none()

        statuses = [AssessmentStatus.PENDING, AssessmentStatus.ACKNOWLEDGED, AssessmentStatus.ACTION_TAKEN]
        status_weights = [0.5, 0.3, 0.2]

        for u, risk in assessment_targets[:20]:
            hr = hr_by_user.get(u.id)
            if not hr:
                continue

            hrv = hr.hrv_baseline_deviation
            duty = hr.avg_weekly_duty_hours
            leave = hr.days_since_last_leave
            deployment = hr.deployment_history_months
            sleep_val = hr.avg_sleep_recovery
            fatigue = hr.avg_fatigue_level
            mood = hr.avg_mood_score

            resilience = compute_resilience(mood, sleep_val, fatigue)
            days_declining = random.randint(3, 12)

            factor_template = pick(FACTORS, risk)
            factor = format_factor(
                factor_template,
                days=leave, hours=round(duty), hrv=hrv,
                sleep=sleep_val / 2, days_d=days_declining,
                leave_overdue=max(0, leave - 90), months=deployment,
            )
            intervention = pick(INTERVENTIONS, risk)
            narrative_template = pick(AI_NARRATIVES, risk)
            narrative = format_factor(
                narrative_template,
                hrv=hrv, months=deployment, hours=round(duty),
                days=leave, days_d=days_declining, sleep=sleep_val,
            )

            status = random.choices(statuses, weights=status_weights)[0]
            resolved_at = None
            if status == AssessmentStatus.ACTION_TAKEN:
                resolved_at = datetime.now(timezone.utc) - timedelta(days=random.randint(1, 7))

            assessment = AIAssessment(
                id=uuid.uuid4(),
                user_id=u.id,
                unit_id=u.unit_id,
                risk_level=risk,
                resilience_score=resilience,
                mood_score=round(mood, 1),
                sleep_recovery=round(sleep_val, 1),
                fatigue_level=round(fatigue, 1),
                hrv_baseline_deviation=hrv,
                contributing_factors=factor,
                recommended_intervention=intervention,
                ai_narrative=narrative,
                status=status,
                acknowledged_by=wo_user.id if wo_user and status != AssessmentStatus.PENDING else None,
                resolved_at=resolved_at,
                created_at=datetime.now(timezone.utc) - timedelta(days=random.randint(0, 5)),
            )
            session.add(assessment)

        await session.commit()
        print(f"  ✅ Created {min(20, len(assessment_targets))} AI assessments")
        print("\n🎉 Seed complete!")
        print("\n📋 Demo credentials:")
        print("  Dashboard Commander : username=cmd_sharma  password=demo123")
        print("  Dashboard WO        : username=wo_meera   password=demo123")
        print("  Flutter (any user)  : PIN=123456 (after activation)")


if __name__ == "__main__":
    asyncio.run(seed())
