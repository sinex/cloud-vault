FROM frostedcarbon/tfc-cli:v1.1 AS tfc-cli
FROM python:3.10-alpine
COPY --from=tfc-cli tfc-cli /bin/
COPY entrypoint.py /entrypoint.py
CMD ["python", "/entrypoint.py"]
