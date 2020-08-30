#/usr/bin/perl

for(my $i=0; $i < 256; $i++) {
    #my $rank = $i & 0x0f;
    my $rank = $i & 0xf0;
    $rank = $rank >> 4;
    if ($rank == 0 || $rank == 14 || $rank == 15) {
        printf("Invalid: %x\n", $i);
    } else {
        printf("Valid: %x\n", $i);
    }
}

