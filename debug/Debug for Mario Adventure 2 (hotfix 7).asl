state("project64") { }
state("retroarch") { }

startup
{
    vars.StarCountAddress = 0x1b6f20;
    vars.LevelIDAddress = 0x1ab9e6;
    vars.AreaIndexAddress = 0x1b6407;
    vars.ActionIDAddress = 0x1b6e84;
    vars.NumVBlanksAddress = 0x116ce4;
    vars.FileAAddress = 0x201fa4;
    
	settings.Add("CompileCheck", false, "If you see this it compiled");
    vars.AddressSearchInterval = 1000;
}

init
{
    current.starCount = 0;
    current.levelID = 0;
    current.areaIndex = 0;
    current.actionID = 0;
    current.numVBlanks = 0;
    current.keyFlagsByte = 0;
    
    vars.baseRAMAddressFound = false;
    vars.stopwatch = new Stopwatch();
    vars.baseRAMAddress = IntPtr.Zero;
    vars.verifyRetriesLeft = 0;
    
    vars.retroarch = game.ProcessName.Contains("retroarch");
}

update
{
    #region Find baseRAMAddress
    if (!vars.baseRAMAddressFound)
    {
        bool onCooldown = vars.stopwatch.IsRunning && vars.stopwatch.ElapsedMilliseconds <= 1000;
        if (onCooldown)
        {
            return false;
        }
        else
        {
            vars.stopwatch.Start();
            vars.baseRAMAddress = IntPtr.Zero;
            
            {
                // Hardcoded values because GetSystemInfo / GetNativeSystemInfo can't return info for remote process
                var min = 0x10000L;
                var max = game.Is64Bit() ? 0x00007FFFFFFEFFFFL : 0xFFFFFFFFL;
                
                var mbiSize = (UIntPtr) 0x30; // Clueless
                
                var addr = min;
                do
                {
                    MemoryBasicInformation mbi;
                    if (WinAPI.VirtualQueryEx(game.Handle, (IntPtr)addr, out mbi, mbiSize) == (UIntPtr)0)
                        break;
                    
                    addr += (long)mbi.RegionSize;
                    
                    if (mbi.State != MemPageState.MEM_COMMIT || (mbi.Protect & MemPageProtect.PAGE_GUARD) != 0 ||
                        mbi.Type != MemPageType.MEM_PRIVATE || ((int) mbi.Protect & (int) 0xcc) == 0)
                        continue;
                    
                    if (vars.retroarch)
                    {
                        ulong size = (ulong)mbi.RegionSize;
                        bool ramFound = false;
                        if (size >= 0x800000)
                        {
                            ulong align = 0x10000;
                            ulong address = (ulong) mbi.BaseAddress;
                            ulong addressAlignedStart = (address + align - 1) / align * align;
                            ulong addressAlignedEnd = (address + size) / align * align;
                            
                            for (ulong probe = addressAlignedStart; probe <= addressAlignedEnd; probe += align)
                            {
                                uint val;
                                var probeAddr = (IntPtr) probe;
                                bool readSuccess = game.ReadValue(probeAddr, out val);
                                if (readSuccess && (val & 0xfffff000) == 0x3C1A8000)
                                {
                                    vars.baseRAMAddress = probeAddr;
                                    ramFound = true;
                                    break;
                                }
                            }
                        }
                        
                        if (ramFound)
                        {
                            break;
                        }
                    }
                    else
                    {
                        uint val;
                        if (game.ReadValue(mbi.BaseAddress, out val) && (val & 0xfffff000) == 0x3C1A8000)
                        {
                            vars.baseRAMAddress = mbi.BaseAddress;
                            break;
                        }
                    }
                } while (addr < max);
            }
            
            if (vars.retroarch)
            {
                var parallelModule = modules.Where(x => x.ModuleName.Contains("parallel_n64")).First();
                var parallelStart = (long) parallelModule.BaseAddress;
                for (long num = 0; num < (long) parallelModule.ModuleMemorySize / 0x1000; num++)
                {
                    uint val;
                    var addr = (IntPtr) (parallelStart + num * 0x1000);
                    if (game.ReadValue(addr, out val) && (val & 0xfffff000) == 0x3C1A8000)
                    {
                        vars.baseRAMAddress = addr;
                        break;
                    }
                }
            }
            
            if (vars.baseRAMAddress == IntPtr.Zero)
            {
                vars.stopwatch.Restart();
                return false;
            }
            else
            {
                vars.stopwatch.Reset();
                vars.baseRAMAddressFound = true;
            }
        }
    }
    #endregion
    
    #region Verify baseRAMAddress is valid
    uint tval;
    if (!game.ReadValue((IntPtr) vars.baseRAMAddress, out tval))
    {
        vars.baseRAMAddressFound = false;
        vars.baseRAMAddress = IntPtr.Zero;
        return false;
    }
    
    if ((tval & 0xfffff000) != 0x3C1A8000)
    {
        if (vars.verifyRetriesLeft == 0)
        {
            vars.baseRAMAddressFound = false;
            vars.baseRAMAddress = IntPtr.Zero;
        }

        vars.verifyRetriesLeft--;
        return false;
    }
    else
    {
        vars.verifyRetriesLeft = 100;
    }
    #endregion
    
    #region Read memory addresses
    current.starCount = memory.ReadValue<short>((IntPtr) (vars.baseRAMAddress + vars.StarCountAddress));
    current.levelID = memory.ReadValue<short>((IntPtr) (vars.baseRAMAddress + vars.LevelIDAddress));
    current.areaIndex = memory.ReadValue<byte>((IntPtr) (vars.baseRAMAddress + vars.AreaIndexAddress));
    current.actionID = memory.ReadValue<uint> ((IntPtr) (vars.baseRAMAddress + vars.ActionIDAddress));
    current.numVBlanks = memory.ReadValue<uint> ((IntPtr) (vars.baseRAMAddress + vars.NumVBlanksAddress));
    current.keyFlagsByte = memory.ReadValue<byte>((IntPtr) (vars.baseRAMAddress + vars.FileAAddress));
    #endregion
    
    var sb = new StringBuilder();
    sb.Append("[ASL] ");
    sb.Append("starCount: " + current.starCount);
    sb.Append(" - levelID: " + current.levelID);
    sb.Append(" - areaIndex: " + current.areaIndex);
    sb.Append(" - actionID: " + current.actionID);
    sb.Append(" - numVBlanks: " + current.numVBlanks);
    sb.Append(" - keyFlagsByte: " + current.keyFlagsByte);
    
    print(sb.ToString());
    
    return true;
}