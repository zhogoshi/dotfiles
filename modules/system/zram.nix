{ ... }:
{
  # zram swap instead of a swap partition (4GB out of 16GB RAM)
  zramSwap = {
    enable        = true;
    memoryPercent = 25;
  };
}
