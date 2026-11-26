import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as GnomeSession from 'resource:///org/gnome/shell/misc/gnomeSession.js';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';

async function logind(method, parameters = null) {
    const reply = await Gio.DBus.system.call(
        'org.freedesktop.login1',
        '/org/freedesktop/login1',
        'org.freedesktop.login1.Manager',
        method,
        parameters,
        null,
        Gio.DBusCallFlags.ALLOW_INTERACTIVE_AUTHORIZATION,
        -1,
        null);
    return reply.deepUnpack();
}

async function bootLoaderEntries() {
    const reply = await Gio.DBus.system.call(
        'org.freedesktop.login1',
        '/org/freedesktop/login1',
        'org.freedesktop.DBus.Properties',
        'Get',
        new GLib.Variant('(ss)', ['org.freedesktop.login1.Manager', 'BootLoaderEntries']),
        null,
        Gio.DBusCallFlags.NONE,
        -1,
        null);
    return reply.recursiveUnpack()[0];
}

const targets = [
    {
        label: 'Restart to BIOS…',
        available: async () => (await logind('CanRebootToFirmwareSetup'))[0] === 'yes',
        set: () => logind('SetRebootToFirmwareSetup', new GLib.Variant('(b)', [true])),
        unset: () => logind('SetRebootToFirmwareSetup', new GLib.Variant('(b)', [false])),
    },
    {
        label: 'Restart to Windows…',
        available: async () => (await logind('CanRebootToBootLoaderEntry'))[0] === 'yes' &&
            (await bootLoaderEntries()).includes('auto-windows'),
        set: () => logind('SetRebootToBootLoaderEntry', new GLib.Variant('(s)', ['auto-windows'])),
        unset: () => logind('SetRebootToBootLoaderEntry', new GLib.Variant('(s)', [''])),
    },
];

export default class RestartTo extends Extension {
    enable() {
        this._session = new GnomeSession.SessionManager();
        this._items = [];
        this._idleId = GLib.idle_add(GLib.PRIORITY_DEFAULT, () => {
            const system = Main.panel.statusArea.quickSettings._system;
            if (!system)
                return GLib.SOURCE_CONTINUE;
            this._idleId = 0;
            this._addItems(system.quickSettingsItems[0].menu).catch(logError);
            return GLib.SOURCE_REMOVE;
        });
    }

    disable() {
        if (this._idleId)
            GLib.source_remove(this._idleId);
        this._idleId = 0;
        this._items.forEach(item => item.destroy());
        this._items = [];
        this._session = null;
    }

    async _addItems(menu) {
        const available = await Promise.all(targets.map(t => t.available().catch(() => false)));
        if (!this._session)
            return;
        targets.filter((_, i) => available[i]).forEach(target => {
            const item = menu.addAction(target.label, () => {
                Main.panel.closeQuickSettings();
                this._restart(target).catch(logError);
            });
            // After Suspend and Restart…, before Power Off…
            menu.moveMenuItem(item, 2 + this._items.length);
            this._items.push(item);
        });
    }

    async _restart(target) {
        await target.set();
        try {
            await this._session.RebootAsync();
        } catch (e) {
            // The restart dialog was cancelled, so the next boot is normal again.
            await target.unset();
            if (!e.matches?.(Gio.IOErrorEnum, Gio.IOErrorEnum.CANCELLED))
                throw e;
        }
    }
}
