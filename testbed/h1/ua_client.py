import asyncio

from asyncua import Client

url = "opc.tcp://10.0.0.2:4840/freeopcua/server/"
namespace = "http://examples.freeopcua.github.io"
timeout = 10.0  # Imposta il timeout a 10 secondi
watchdog_interval = 2.0  # Imposta l'intervallo del watchdog a 2 secondi

async def main():

    print(f"Connecting to {url} ...")
    async with Client(url=url, timeout=timeout, watchdog_intervall=watchdog_interval) as client:
        
        # Find the namespace index
        nsidx = await client.get_namespace_index(namespace)
        print(f"Namespace Index for '{namespace}': {nsidx}")

        # Get the variable node for read / write
        var = await client.nodes.root.get_child(
            ["0:Objects", f"{nsidx}:MyObject", f"{nsidx}:MyVariable"]
        )
        value = await var.read_value()
        print(f"Value of MyVariable ({var}): {value}")

        new_value = value - 50
        print(f"Setting value of MyVariable to {new_value} ...")
        await var.write_value(new_value)

if __name__ == "__main__":
    asyncio.run(main())