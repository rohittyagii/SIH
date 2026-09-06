import asyncio
import uuid
import sys
import os

# Add backend directory to Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy import select
from app.config import get_settings
from app.models.user import Unit, ActivationCode

async def main():
    settings = get_settings()
    engine = create_async_engine(settings.DATABASE_URL)
    session_maker = async_sessionmaker(engine, class_=AsyncSession)
    
    async with session_maker() as session:
        # Get first unit
        result = await session.execute(select(Unit))
        unit = result.scalars().first()
        
        # Create code
        code = ActivationCode(id=uuid.uuid4(), code="DEMO-1234", unit_id=unit.id, is_used=False)
        session.add(code)
        await session.commit()
        print("✅ Demo activation code DEMO-1234 created successfully!")

asyncio.run(main())
