# import gi
# gi.require_version('Geoclue', '2.0')
# from gi.repository import Gio, GLib
# from gi.repository import Geoclue

# clue = Geoclue.Simple.new_sync('something',Geoclue.AccuracyLevel.NEIGHBORHOOD ,None)
# print(clue)
# location = clue.get_location()
# print(location.get_property('latitude'), location.get_property('longitude'))


# import dbus
# import os
# from dbus.mainloop.glib import DBusGMainLoop
# from gi.repository import GLib, Gio
# def pulse_bus_address():
#     if 'PULSE_DBUS_SERVER' in os.environ:
#         address = os.environ['PULSE_DBUS_SERVER']
#     else:
#         bus = dbus.SessionBus()
#         server_lookup = bus.get_object("org.PulseAudio1", "/org/pulseaudio/server_lookup1")
#         address = server_lookup.Get("org.PulseAudio.ServerLookup1", "Address", dbus_interface="org.freedesktop.DBus.Properties")
#         print(address)

#     return address

# def sig_handler(state):
#     print("State changed to %s" % state)

# # setup the glib mainloop

# DBusGMainLoop(set_as_default=True)

# loop = GLib.MainLoop()

# conn = Gio.DBusConnection.new_for_address_sync(pulse_bus_address(), Gio.DBusConnectionFlags.NONE, None, None)
# conn.signal_subscribe(None, 'org.PulseAudio.Core1.Device', 'MuteUpdated', None, None, Gio.DBusSignalFlags.NONE, sig_handler, None)



# pulse_core = pulse_bus.get_object(object_path='/org/pulseaudio/core1')
# pulse_core.ListenForSignal('org.PulseAudio.Core1.Device.MuteUpdated', dbus.Array(signature='o'), dbus_interface='org.PulseAudio.Core1')

# pulse_bus.add_signal_receiver(sig_handler, 'MuteUpdated')
# loop.run()



import dbus, gobject
from dbus.mainloop.glib import DBusGMainLoop

def msg_cb(bus, msg):
    args = msg.get_args_list()
    print("Notification from '%s'" % args[0])
    print("Summary: %s" % args[3])
    print("Body: %s", args[4])

if __name__ == '__main__':
    DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()

    string = "interface='org.freedesktop.Notifications',member='Notify'"
    bus.add_match_string(string)
    bus.add_message_filter(msg_cb)

    mainloop = gobject.MainLoop ()
    mainloop.run ()
