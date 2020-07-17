# Overview of the build process

## Master Boot Record Programs/Bootloaders

```
<foo>.s -->
    <foo>.o

<foo>.o &
bootsector.ld -->
    <foo>.bootsector
```

## Stage-1 Programs/Bootloaders

```
<foo>.<mode>.s -->
    <foo>.<mode>.o

<foo>.<mode>.o &
stage1.ld -->
    <foo>.<mode>.stage1 -->
        <foo>.<mode>.sectorCount.o
```

```
stage0.<mode>.s -->
    stage0.<mode>.o

stage0.<mode>.o &
<foo>.<mode>.sectorCount.o &
bootsector.ld -->
    <foo>.<mode>.stage0
```

```
<foo>.<mode>.stage0 &
<foo>.<mode>.stage1 &
-->
    <foo>.<mode>.img
```
