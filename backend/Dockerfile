FROM dart:stable

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

COPY lib ./lib

ENV PORT=8080
EXPOSE 8080

CMD ["dart", "run", "lib/server.dart"]