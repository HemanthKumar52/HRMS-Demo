# PPULSE HRMS — Performance Report

## Response Times (measured on localhost, debug mode)

| Operation | Avg (ms) | Notes |
|-----------|----------|-------|
| Login API | 120 | JWT generation |
| Dashboard load | 200 | Parallel API calls |
| Face verify (warm) | 150-300 | Model already loaded |
| Face verify (cold) | 2000 | First-time model load |
| Leave apply | 100 | Single DB write |
| Notification poll | 50 | Lightweight query |
| Team attendance | 150 | Manager's direct reports |

## Mobile Performance

| Metric | Value |
|--------|-------|
| iOS build size | 22.4 MB |
| Android APK (debug) | ~45 MB |
| App startup (cold) | ~2.5s |
| Screen transitions | 60 FPS (spring animations) |
| Memory usage (idle) | ~120 MB |

## Scalability

- **Database:** PostgreSQL with indexed FKs. Connection pooling via pgBouncer for 100+ concurrent users.
- **Face Model:** Singleton — 200MB RAM, loaded once. Supports ~10 verifications/second on 4-core CPU.
- **API:** Stateless JWT allows horizontal scaling behind load balancer.
- **Caching:** Dashboard summary cacheable with 30s TTL.
- **CDN:** Static assets (icons, fonts) served via Nginx/CDN.

---

**PPULSE Technologies**
