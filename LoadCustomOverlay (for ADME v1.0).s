.thumb

@ Thanks to: Mikelan98, Nomura: ARM9 Expansion Subroutine (pokehacking.com/r/20041000)

LoadCustomOverlay: @ hook at 0x0206D554
  push {lr}
  push {r0-r7}
  sub sp, #0x3C

  @ FileInfo fileInfo; // at sp
  @ OpenFile(&fileInfo, custom_overlay_path, 4, NULL);
  mov r0, sp
  adr r1, custom_overlay_path
  mov r2, #4
  mov r3, #0
  ldr r7, =0x0206431d
  blx r7

  @ ReadFile(&fileInfo, (void*) 0x022C1000, fileInfo.fileEnd - fileInfo.fileStart);
  mov r0, sp
  ldr r1, =0x022C1000
  ldr r2, [sp, #0x28]
  ldr r3, [sp, #0x24]
  sub r2, r3
  ldr r7, =0x02119334
  blx r7

  @ CloseFile(&fileInfo);
  mov r0, sp
  ldr r7, =0x02119460
  blx r7

  @ restore overwritten code
  add sp, #0x3C
  pop {r0-r7}
  ldr r0, =0x10000
  orr r1, r0

  pop {pc}

custom_overlay_path:
  .asciz "/sky/d_2d_weather_test_ncl.bin"
