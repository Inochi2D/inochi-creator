"""Get the development dependecies for Inochi2D Creator"""
import logging
import subprocess
from argparse import ArgumentParser
from argparse import Namespace
from pathlib import Path

URL = str

DEPS: dict[str, URL] = {
    "vmc-d": "https://github.com/Inochi2D/vmc-d.git",
    "bindbc-imgui": "https://github.com/Inochi2D/bindbc-imgui.git",
    "inui": "https://github.com/Inochi2D/inui.git",
    "inochi2d": "https://github.com/Inochi2D/inochi2d.git",
    "psd-d": "https://github.com/Inochi2D/psd-d.git",
    "gitver": "https://github.com/Inochi2D/gitver.git",
    "facetrack-d": "https://github.com/Inochi2D/facetrack-d.git",
    "i18n-d": "https://github.com/KitsunebiGames/i18n",
}


def parse_sdl_file(path: Path) -> dict[str, str]:
    """Parse dub SDL file and return dependency versions"""
    versions: dict[str, str] = dict()
    with path.open("r") as fp:
        for line in fp:
            if line.startswith("dependency"):
                line = line.strip()
                _, name, version = line.split()
                name = name[1:-1]
                version = version.split("=")[-1][3:-1]
                logging.debug(f"Found dependecy: {name}-{version}")
                versions[name] = version

    return versions


def cli() -> Namespace:
    """Argument Parsing Definition"""
    parser = ArgumentParser(
        description="Get dev dependecies for Inochi2D Creator from Git"
    )
    parser.add_argument(
        "--dep",
        action="append",
        choices=[key for key in DEPS.keys()],
        help="Which dep to get from git (default: all from Inochi2D git group)",
    )
    parser.add_argument(
        "--dub-sdl",
        type=Path,
        default=Path("./dub.sdl"),
        help="Path to the dub.sdl file defining the dependencies",
    )
    parser.add_argument(
        "--clone-path",
        type=Path,
        default=Path("./deps"),
        help="Where to clone the dependencies (default: ./deps)",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Increase Verbosity",
    )
    return parser.parse_args()


def main() -> None:
    """Script entry point"""
    args = cli()

    # Set logging verbosity
    logging.basicConfig(level=logging.DEBUG if args.verbose else logging.INFO)

    sdl_path: Path = args.dub_sdl.resolve()
    logging.debug(f"Reading dependecy info from {sdl_path}")
    versions = parse_sdl_file(sdl_path)

    # Dependecies
    deps = args.dep
    if args.dep is None:
        logging.info("No deps selected, getting all")
        deps = [key for key in DEPS.keys()]

    deps_path: Path = args.clone_path.resolve()
    logging.debug(f"Cloning deps to {deps_path}")
    for dep in deps:
        if dep not in versions:
            logging.warning(f"Couldn't find version for {dep}, skipping")
            continue

        url = DEPS[dep]
        dep_path = deps_path / dep
        version = versions[dep]
        logging.info(f"Clonning git repo for {dep} to {dep_path}")

        logging.debug(f"Git url: {url}")
        subprocess.run(["git", "clone", "--recursive", url, f"{dep_path}"])
        logging.info(f"Adding package to dub {dep}-{version}")
        subprocess.run(["dub", "add-local", f"{dep_path}", version])


if __name__ == "__main__":
    main()
