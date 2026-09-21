FROM mcr.microsoft.com/dotnet/aspnet:6.0-bookworm-slim AS base

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    libfontconfig1 \
    libicu-dev \
    libgdiplus \
    libc6-dev \
    libx11-dev \
    libxext-dev \
    libxrender-dev \
    libgl1 \
    libopengl0 \
    libharfbuzz0b \
    libfreetype6 \
    fontconfig \
    && rm -rf /var/lib/apt/lists/*

# Copy and setup fonts
COPY fonts /usr/share/fonts/truetype/custom/
RUN fc-cache -f -v

WORKDIR /app
EXPOSE 80
ENV SYNCFUSION_LICENSE_KEY=""
ENV SPELLCHECK_DICTIONARY_PATH=""
ENV SPELLCHECK_JSON_FILENAME=""
ENV SPELLCHECK_CACHE_COUNT=""
ENV LD_LIBRARY_PATH="/app/runtimes/linux-arm64/native:/usr/lib:/usr/local/lib:${LD_LIBRARY_PATH}"

FROM mcr.microsoft.com/dotnet/sdk:6.0-bookworm-slim AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    libfontconfig1 \
    libicu-dev \
    libgdiplus \
    libc6-dev \
    libx11-dev \
    libxext-dev \
    libxrender-dev \
    libgl1 \
    libopengl0 \
    libharfbuzz0b \
    libfreetype6 \
    fontconfig \
    && rm -rf /var/lib/apt/lists/*

# Copy and setup fonts
COPY fonts /usr/share/fonts/truetype/custom/
RUN fc-cache -f -v

WORKDIR /source
COPY ["src/ej2-documenteditor-server/ej2-documenteditor-server.csproj", "./ej2-documenteditor-server/ej2-documenteditor-server.csproj"]
COPY ["src/ej2-documenteditor-server/NuGet.Config", "./ej2-documenteditor-server/"]
RUN dotnet restore "./ej2-documenteditor-server/ej2-documenteditor-server.csproj"
COPY . .
WORKDIR "/source/src"
RUN dotnet build -c Release -o /app

FROM build AS publish
RUN dotnet publish -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
RUN chmod +x runtimes/linux-arm64/native/libSkiaSharp.so || true
ENTRYPOINT ["dotnet", "ej2-documenteditor-server.dll"]