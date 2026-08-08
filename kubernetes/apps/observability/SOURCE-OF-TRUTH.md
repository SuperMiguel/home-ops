# Monitoring source of truth

## The failure mode we hit

Hardcoding **IPs** in Gatus (or inventory) drifts when gear is replaced (Dahua → Protect),
DHCP changes, or VLANs move. Alerts then page on ghosts — or miss the real device.

## Rules

1. **If UniFi knows the device, Unpoller owns the alert.**
   Use `unpoller_client_uptime_seconds{mac="…"}` / `unpoller_device_*`, never a frozen IP.
   MACs survive IP renumbering; UniFi adoption state survives ICMP/firewall quirks.

2. **Gatus is for things UniFi cannot see.**
   In-cluster HTTP/TCP (`*.svc.cluster.local`), and rare hosts missing from Unpoller
   (e.g. water softener, wiki, nodes not showing as clients).

3. **Inventory markdown is documentation, not the monitor.**
   `Super-Veliz-Network/docs/network/network-inventory.md` should be refreshed from UniFi/Unpoller
   when hardware changes — it must not be the only place an IP lives for alerting.

4. **CCTV is Unpoller-only.**
   Servers→CCTV ICMP is blocked by design; Protect cams are `network="CCTV"` clients.

## When you add a device

| Device type | Where to alert |
| --- | --- |
| UniFi AP/switch/PDU/UDM | Unpoller device metrics (already covered) |
| Anything in UniFi client list | Unpoller `mac=` rule in `unpoller-rules` |
| K8s / in-cluster service | Gatus HTTP/TCP to Service DNS |
| Not in UniFi at all | Gatus ICMP/HTTP to current IP, and note it in inventory |

After replacing a camera/hub: update the **MAC** in `unpoller-rules` (and inventory notes).
Do not add a new Gatus ICMP IP for UniFi-managed gear.
