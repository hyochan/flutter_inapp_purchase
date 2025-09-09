#
# Generated file, do not edit.
#

import lldb

def handle_new_rx_page(frame: lldb.SBFrame, bp_loc, extra_args, intern_dict):
    """Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages."""
    # Use SBFrame.FindRegister instead of non-standard frame.register
    reg_x0 = frame.FindRegister("x0")
    reg_x1 = frame.FindRegister("x1")
    if not reg_x0 or not reg_x0.IsValid() or not reg_x1 or not reg_x1.IsValid():
        print("Failed to read registers x0/x1")
        return
    base = reg_x0.GetValueAsUnsigned()
    page_len = reg_x1.GetValueAsUnsigned()
    if not base or not page_len:
        print(f"Invalid base/page_len: base={base}, page_len={page_len}")
        return

    # Note: NOTIFY_DEBUGGER_ABOUT_RX_PAGES will check contents of the
    # first page to see if handled it correctly. This makes diagnosing
    # misconfiguration (e.g. missing breakpoint) easier.
    prefix = b"IHELPED!"
    write_len = min(len(prefix), page_len)

    error = lldb.SBError()
    bytes_written = frame.GetThread().GetProcess().WriteMemory(
        base, prefix[:write_len], error
    )
    if not error.Success() or bytes_written != write_len:
        print(f"Failed to write into 0x{base:x}[+{page_len}]", error)
        return

def __lldb_init_module(debugger: lldb.SBDebugger, _):
    target = debugger.GetDummyTarget()
    # Caveat: must use BreakpointCreateByRegEx here and not
    # BreakpointCreateByName. For some reasons callback function does not
    # get carried over from dummy target for the later.
    bp = target.BreakpointCreateByRegex("^NOTIFY_DEBUGGER_ABOUT_RX_PAGES$")
    bp.SetScriptCallbackFunction('{}.handle_new_rx_page'.format(__name__))
    bp.SetAutoContinue(True)
    print("-- LLDB integration loaded --")
