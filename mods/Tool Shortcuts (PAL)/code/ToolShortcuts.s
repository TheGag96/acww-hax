.thumb

.include "includes_for_ToolShortcuts.s"

ToolShortcuts: @ hook at 0x0200FFEA
  push {lr}
  push {r0-r7}

  @ main data (?) pointer is in r4

  mov r0, r4
  ldr r5, =shortcut+1
  blx r5

end:
  @ restore overwritten code
  pop {r0-r7}
  mov r0, r4
  mov r1, #0x13

  pop {pc}
