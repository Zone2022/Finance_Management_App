## Why
The existing notification parser rejects the actual English Weixin and Chinese Alipay notifications observed on the user's phone. AI credentials are lost on restart and diagnostics are missing.

## What Changes
- Recognize explicit payment notifications from WeChat, Alipay and China Construction Bank while rejecting income and refunds.
- Persist AI provider credentials in platform secure storage; allow explicit selection between DeepSeek and Claude.
- Provide local bounded diagnostics and notification listener status without retaining sensitive notification content.

## Capabilities
### New Capabilities
- `payment-diagnostics-ai`: Payment parsing, diagnostics and AI provider configuration.
### Modified Capabilities
- None; this is a new behavioral specification for existing implementation.

## Impact
Android listener, settings screens, encrypted credential storage, classification service and test coverage. Bank and payment notices can describe the same transaction and must be reviewed by the user.
