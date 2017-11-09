import sqlalchemy as sqla
from sqlalchemy.ext.declarative import declarative_base as sqla_declarative_base

# sudo apt-get install libmysqlclient-dev
# pip install mysql-python

Base = sqla_declarative_base()
engine = sqla.create_engine('sqlite:///:memory:', echo=True)
#engine = sqla.create_engine('mysql://root:root@localhost:3306/test', echo=True)
Session = sqla.orm.sessionmaker(bind=engine)


class LoadBalancers(Base):
    __tablename__ = 'loadbalancers'

    id = sqla.Column(sqla.String, primary_key=True)
    cluster_id = sqla.Column(sqla.String, nullable=False)
    zone_id = sqla.Column(sqla.String, nullable=False)
    in_vpc = sqla.Column(sqla.String, default=False, nullable=False)
    deleted = sqla.Column(sqla.Boolean, default=False, nullable=False)


class Clusters(Base):
    __tablename__ = 'clusters'

    id = sqla.Column(sqla.String, primary_key=True)
    zone_id = sqla.Column(sqla.String, nullable=False)
    in_vpc = sqla.Column(sqla.Boolean, default=False, nullable=False)
    deleted = sqla.Column(sqla.Boolean, default=False, nullable=False)


if __name__ == "__main__":
    Base.metadata.create_all(engine)

    clusters = [
        Clusters(id='c0', zone_id='z0', in_vpc=False),
        Clusters(id='c1', zone_id='z0', in_vpc=False),
        Clusters(id='c2', zone_id='z0', in_vpc=False),
        Clusters(id='c3', zone_id='z1', in_vpc=False),
    ]
    loadbalancers = [
        LoadBalancers(id='l0', cluster_id='c0', zone_id='z0', in_vpc=False),
        LoadBalancers(id='l1', cluster_id='c0', zone_id='z0', in_vpc=False),
        LoadBalancers(id='l2', cluster_id='c1', zone_id='z0', in_vpc=False),
    ]

    session = Session()
    for cluster in clusters:
        session.add(cluster)
    for loadbalancer in loadbalancers:
        session.add(loadbalancer)
    session.commit()

    zone_id = 'z0'
    in_vpc = False

    #q = session.query(Clusters).filter(sqla.and_(Clusters.zone_id==zone_id, Clusters.in_vpc==in_vpc))
    #print q.all()

    q = session.query(Clusters.id, sqla.func.count(LoadBalancers.id).label('count')) \
            .outerjoin(LoadBalancers, sqla.and_( \
                    LoadBalancers.deleted==False, \
                    LoadBalancers.cluster_id==Clusters.id)) \
            .filter(sqla.and_( \
                    Clusters.deleted==False, \
                    Clusters.zone_id==zone_id, \
                    Clusters.in_vpc==in_vpc)) \
            .group_by(Clusters.id) \
            .order_by('count')
    v = q.first()
    print v.id
