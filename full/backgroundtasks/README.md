# Portable BackgroundTasks

This directory implements Apple's `BackgroundTasks` source identity as a real
framework product for the Linux-hosted ARM64 Mach-O platform. It includes task
request snapshots, registration, pending-query and cancellation APIs, queue
delivery, task expiration/completion, Darwin-shaped scheduler errors, and a
narrow host SPI for launching due work.

The default is deliberately honest: Linux has no Apple background-task daemon.
Availability and permitted identifiers are host policy, and state is
process-local. Unchanged application source continues to import
`BackgroundTasks` and link `libBackgroundTasks.dylib`.

The combined host gate first typechecks the untouched consumer call shapes
against Apple's iPhoneOS SDK, then typechecks the same bytes against the portable
module and exercises the runtime:

```sh
bash full/backgroundtasks/tests/test_background_spotlight_host.sh
```
