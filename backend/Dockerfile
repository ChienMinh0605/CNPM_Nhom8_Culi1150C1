# Build và chạy backend DCSV (C++20 + Drogon).
FROM drogonframework/drogon:v1.9.14 AS build
WORKDIR /src
COPY CMakeLists.txt ./
COPY src ./src
RUN cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=OFF \
 && cmake --build build --target dcsv_server -j"$(nproc)"

FROM drogonframework/drogon:v1.9.14
WORKDIR /app
COPY --from=build /src/build/dcsv_server /app/dcsv_server
EXPOSE 8080
CMD ["/app/dcsv_server"]
