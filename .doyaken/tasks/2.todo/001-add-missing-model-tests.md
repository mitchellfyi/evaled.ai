# Add Missing Model Tests

## Summary
Several models lack dedicated test files, reducing test coverage.

## Priority
Medium

## Details
The following models need test files created:

1. **agent_tag** - Join model for agent-tag associations
   - Test uniqueness validation on agent_id + tag_id

2. **agent_telemetry_stat** - Telemetry aggregation stats
   - Test period validations
   - Test numericality validations

3. **role** - Rolify role model
   - Basic existence test

4. **security_certification** - Security certifications
   - Test status transitions
   - Test active scope
   - Test expiry logic

5. **tag** - Agent tags
   - Test slug generation
   - Test popular scope

6. **webhook_delivery** - Webhook delivery records
   - Test status tracking
   - Test retry logic if any

7. **webhook_endpoint** - Webhook endpoints
   - Test URL validation
   - Test event filtering
   - Test secret generation

## Acceptance Criteria
- [ ] Create test file for each model
- [ ] Test all validations
- [ ] Test scopes
- [ ] Test any instance methods
- [ ] All tests pass

## References
- Discovery: Codebase review 2025-02-10
- Files: test/models/

## Notes
Factory files may already exist in test/factories/ for some of these models.
