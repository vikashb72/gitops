# Strimzi Kafka 

# Testing

kubectl -n kafka-system run kafka-producer -ti \
    --image=quay.io/strimzi/kafka:0.45.0-kafka-3.8.0 \
    --rm=true --restart=Never \
    -- bin/kafka-console-producer.sh \
    --bootstrap-server kafka-cluster-kafka-bootstrap:9092 \
    --topic test.topic.1


kubectl -n kafka-system run kafka-consumer -ti \
    --image=quay.io/strimzi/kafka:0.45.0-kafka-3.8.0 \
    --rm=true --restart=Never \
    -- bin/kafka-console-consumer.sh \
    --bootstrap-server kafka-cluster-kafka-bootstrap:9092 \
    --topic test.topic.1 --from-beginning

